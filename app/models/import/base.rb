# frozen_string_literal: true

class Import::Base < ApplicationModel
  self.table_name = "imports"

  class << self
    def model_name
      @_model_name ||= ActiveModel::Name.new(Import::Base, Import::Base, 'Import').tap do |model_name| # rubocop:disable Naming/MemoizedInstanceVariableName
        model_name.instance_variable_set(:@i18n_key, name.underscore) unless self == ::Import::Base
      end
    end
  end

  include OptionsSupport
  include NotifiableSupport
  include PurgeableResource

  after_initialize :set_defaults

  has_many :processings, as: :operation, dependent: :destroy
  has_array_of :overlapping_referentials, class_name: '::Referential'
  belongs_to :code_space, default: -> { default_code_space } # CHOUETTE-3247 optional: false

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

  def workgroup_control_list_run
    @workgroup_control_list_run ||= \
      processings.where.not(workgroup_id: nil)
                 .where(processed_type: 'Control::List::Run')
                 .joins(
                   "INNER JOIN #{::Control::List::Run.quoted_table_name} ON" \
                     "#{::Control::List::Run.quoted_table_name}.id = #{::Processing.quoted_table_name}.processed_id"
                 ) \
                 .take
  end

  def workbench_macro_list_run
    @workbench_macro_list_run ||= \
      processings.where(workgroup_id: nil)
                 .where(processed_type: 'Macro::List::Run')
                 .joins(
                   "INNER JOIN #{::Macro::List::Run.quoted_table_name} ON" \
                     "#{::Macro::List::Run.quoted_table_name}.id = #{::Processing.quoted_table_name}.processed_id"
                 ) \
                 .take
  end

  def workbench_control_list_run
    @workbench_control_list_run ||= \
      processings.where(workgroup_id: nil)
                 .where(processed_type: 'Control::List::Run')
                 .joins(
                   "INNER JOIN #{::Control::List::Run.quoted_table_name} ON " \
                     "#{::Control::List::Run.quoted_table_name}.id = #{::Processing.quoted_table_name}.processed_id"
                 ) \
                 .take
  end

  def workgroup
    workbench&.workgroup
  end

  def public_code_space
    @public_code_space ||= workgroup.code_spaces.public if workgroup
  end

  def update_workgroup_providers?
    options['update_workgroup_providers'] || parent_option('update_workgroup_providers') == 'true'
  end

  def store_xml?
    options['store_xml'] || parent_option('store_xml') == 'true'
  end

  def disable_missing_resources?
    options['disable_missing_resources'] || parent_option('disable_missing_resources') == 'true'
  end

  def strict_mode?
    options['strict_mode'] == 'true' || parent_option('strict_mode') == 'true'
  end

  def ignore_particulars?
    options['ignore_particulars'] == 'true' || parent_option('ignore_particulars') == 'true'
  end

  def ignore_parent_stop_areas?
    options['ignore_parent_stop_areas'] == 'true' || parent_option('ignore_parent_stop_areas') == 'true'
  end

  def parent_options
    parent&.options
  end

  def parent_option(key)
    parent_options.present? && parent_options[key]
  end

  PERIOD_EXTREME_VALUE = 25.years

  after_create :purge_imports

  def self.messages_class_name
    "Import::Message"
  end

  def self.resources_class_name
    "Import::Resource"
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

  def line_provider_id
    return unless parent&.options
    parent.options['line_provider_id']
  end

  def line_provider
    @line_provider ||= (workbench.line_providers.find_by(id: line_provider_id) || workbench.default_line_provider)
  end

  def stop_area_provider_id
    return unless parent&.options
    parent.options['stop_area_provider_id']
  end

  def stop_area_provider
    @stop_area_provider ||= (workbench.stop_area_providers.find_by(id: stop_area_provider_id) || workbench.default_stop_area_provider)
  end

  def specific_default_company_id
    return unless parent&.options
    parent.options['specific_default_company_id']
  end

  def specific_default_company
    @specific_default_company ||= workbench.companies.find_by(id: specific_default_company_id)
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

  def default_code_space
    workgroup.code_spaces.default if workgroup
  end

  def set_defaults
    self.code_space ||= default_code_space
  end

  private

  def initialize_fields
    super
    self.token_download ||= SecureRandom.urlsafe_base64
  end
end
