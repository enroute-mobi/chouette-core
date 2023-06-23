class Import::Base < ApplicationModel
  self.table_name = "imports"
  include OptionsSupport
  include NotifiableSupport
  include PurgeableResource
  include ProfilingSupport

  attr_accessor :code_space
  after_initialize :initialize_space_code

  has_many :processings, as: :operation

  scope :unfinished, -> { where 'notified_parent_at IS NULL' }
  scope :having_status, ->(statuses) { where(status: statuses ) }
  scope :started_at_after, ->(date) do
    where('started_at > ?', date)
  end
  scope :started_at_before, ->(date) do
    where('started_at < ?', date)
  end
  scope :started_at_between, ->(start_date, end_date) do
    where('started_at BETWEEN :begin AND :end', begin: start_date, end: end_date)
  end

  def self.mailer_name
    'ImportMailer'
  end

  def file_extension_whitelist
    %w(zip)
  end

  def worgroup_control_list_run
    processings.where("workgroup_id IS NOT NULL AND processed_type = ?", 'Control::List::Run').take
  end

  def workbench_macro_list_run
    processings.where(processed_type: 'Macro::List::Run', workgroup_id: nil).take
  end

  def workbench_control_list_run
    processings.where(processed_type: 'Control::List::Run', workgroup_id: nil).take
  end

  def workgroup
    workbench&.workgroup
  end

  def code_space_default
    # User option in the future
    @code_space ||= workgroup.code_spaces.default if workgroup
  end

  def public_code_space
    @public_code_space ||= workgroup.code_spaces.public if workgroup
  end

  def update_workgroup_providers?
    if options['update_workgroup_providers']
      true
    elsif (parent_options = parent&.options).present?
      parent_options['update_workgroup_providers'] == 'true'
    else
      false
    end
  end

  def store_xml?
    if options['store_xml']
      true
    elsif (parent_options = parent&.options).present?
      parent_options['store_xml'] == 'true'
    else
      false
    end
  end

  def disable_missing_resources?
    if options['disable_missing_resources']
      true
    elsif (parent_options = parent&.options).present?
      parent_options['disable_missing_resources'] == 'true'
    else
      false
    end
  end

  def strict_mode?
    if options['strict_mode'] == 'true'
      true
    elsif (parent_options = parent&.options).present?
      parent_options['strict_mode'] == 'true'
    else
      false
    end
  end

  PERIOD_EXTREME_VALUE = 25.years

  after_create :purge_imports

  def self.messages_class_name
    "Import::Message"
  end

  def self.resources_class_name
    "Import::Resource"
  end

  def self.human_name
    I18n.t("import.#{short_type}")
  end

  def self.short_type
    @short_type ||= self.name.demodulize.underscore
  end

  def short_type
    self.class.short_type
  end

  scope :workbench, -> { where type: "Import::Workbench" }

  include IevInterfaces::Task
  # we skip validation once the import has been persisted,
  # in order to allow async workers (which don't have acces to the file) to
  # save the import
  validates_presence_of :file, unless: Proc.new {|import| @local_file.present? || import.persisted? || import.errors[:file].present? }

  validates_presence_of :workbench

  def self.maximum_runtime
    SmartEnv['CHOUETTE_IMPORT_MAX_RUN_TIME'] ? SmartEnv['CHOUETTE_IMPORT_MAX_RUN_TIME'].hours : Delayed::Worker.max_run_time
  end

  scope :outdated, -> { where(
        'created_at < ? AND status NOT IN (?)',
        maximum_runtime.ago,
        finished_statuses
      )
  }

  def self.abort_old
    outdated.each do |import|
      Rails.logger.error("#{import.class.name} #{import.id} #{import.name} takes too much time and is aborted")
      import.update_attribute(:status, "aborted")
    end
  end

  def self.model_name
    ActiveModel::Name.new Import::Base, Import::Base, "Import"
  end

  # call this method to mark an import as failed, as weel as the resulting referential
  def force_failure!
    if parent
      parent.force_failure!
      return
    end

    do_force_failure!
  end

  def do_force_failure!
    children.each &:do_force_failure!

    update status: 'failed', ended_at: Time.now
    referential&.failed!
    resources.map(&:referential).compact.each &:failed!
    notify_parent
  end

  def purge_imports
    workbench.imports.file_purgeable.where.not(file: nil).each do |import|
      import.update(remove_file: true)
    end
    workbench.imports.purgeable.destroy_all
  end

  def file_type
    return unless file

    get_file_type = ->(*import_types) do
      import_types.each do |import_type|
        return import_type.demodulize.underscore.to_sym if import_type.constantize.accepts_file?(file.path)
      end

      return nil
    end

    case import_category
    when 'automatic'
      import_types = workgroup.import_types.presence || [Import::Gtfs, Import::Netex, Import::Neptune, Import::NetexGeneric, Import::Shapefile].map(&:name)

      get_file_type.call(*import_types)
    when 'shape_file'
      get_file_type.call(Import::Shapefile.name)
    when 'netex_generic'
      get_file_type.call(Import::NetexGeneric.name)
    else
      nil
    end
  end

  # Returns all attributes of the imported file from the user point of view
  def user_file
    Chouette::UserFile.new basename: name.parameterize, extension: file_extension, content_type: content_type
  end

  # Expected and used file content type
  def content_type
    content_type = file&.content_type

    # Some zip files are viewed as "application/octet-stream"
    case content_type
    when "application/octet-stream"
      "application/zip"
    else
      content_type
    end
  end

  def line_ids
    unless referential
      return children.map(&:line_ids).flatten.uniq
    end

    referential.metadatas.pluck(:line_ids).flatten.uniq
  end

  def line_provider
    workbench.line_providers.find_by(id: (parent&.options || {})['line_provider_id']) ||
    workbench.default_line_provider
  end

  protected

  # Expected and used file extension
  def file_extension
    case content_type
    when "application/zip", "application/x-zip-compressed"
      "zip"
    when "application/xml", "text/xml"
      "xml"
    end
  end

  private

  def initialize_fields
    super
    self.token_download ||= SecureRandom.urlsafe_base64
  end

  def initialize_space_code
    unless self.code_space.present?
      self.code_space = code_space_default
    end
  end
end
