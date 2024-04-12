require 'net/http/post/multipart'

class Export::Base < ApplicationModel
  self.table_name = 'exports'

  include OptionsSupport
  include NotifiableSupport
  include PurgeableResource
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TagHelper
  include IconHelper
  include OperationsHelper
  extend Enumerize

  belongs_to :referential
  belongs_to :publication
  belongs_to :workgroup, class_name: '::Workgroup'
  belongs_to :workbench, class_name: "::Workbench"

  has_one :organisation, through: :workbench
  has_many :publication_api_sources, foreign_key: :export_id
  has_many :messages, class_name: 'Export::Message', dependent: :delete_all, foreign_key: "export_id"
  has_many :exportables, dependent: :destroy, class_name: '::Exportable', foreign_key: 'export_id'

  attr_accessor :synchronous
  enumerize :status, in: %w(new pending successful warning failed running aborted canceled), scope: true, default: :new
  mount_uploader :file, ImportUploader

  validates :type, presence: true, inclusion: { in: proc { |e|
                                                      e.workgroup&.export_types || ::Workgroup::DEFAULT_EXPORT_TYPES
                                                    } }
  validates_presence_of :workgroup, :referential_id
  validates :options, export_options: true
  validates :name, presence: true
  validates_presence_of :creator
  validates_integrity_of :file

  before_save :initialize_fields, on: :create
  def initialize_fields
    self.token_upload ||= SecureRandom.urlsafe_base64
  end

  def has_feature?(feature)
    organisation = self.organisation || workgroup&.owner
    organisation&.has_feature?(feature)
  end

  after_create :purge_exports
  def purge_exports
    return unless workbench.present?

    workbench.exports.file_purgeable.where.not(file: nil).each do |export|
      export.update(remove_file: true)
    end
    workbench.exports.purgeable.destroy_all
  end

  before_save :resolve_line_ids
  def resolve_line_ids
    return unless respond_to?(:line_ids) # To delete when java export is disabled
    return unless line_ids.nil? # Useless to update line_ids if line_ids exists

    options = Export::Scope::Options.new(referential, date_range: date_range, line_ids: line_ids,
                                                      line_provider_ids: line_provider_ids, company_ids: company_ids)
    self.line_ids = options.line_ids
  end

  scope :not_used_by_publication_apis, lambda {
    joins('LEFT JOIN public.publication_api_sources ON publication_api_sources.export_id = exports.id')
      .where('publication_api_sources.id IS NULL')
  }
  scope :purgeable, lambda {
    not_used_by_publication_apis.where('exports.created_at <= ?', clean_after.days.ago)
  }
  scope :having_status, ->(statuses) { where(status: statuses) }
  scope :started_at_after, lambda { |date|
    where('started_at > ?', date)
  }
  scope :started_at_before, lambda { |date|
    where('started_at < ?', date)
  }
  scope :started_at_between, lambda { |start_date, end_date|
    where('started_at BETWEEN :begin AND :end', begin: start_date, end: end_date)
  }

  scope :successful, -> { where(status: :successful) }

  def file_extension_whitelist
    %w[zip csv json]
  end

  class << self
    def launched_statuses
      %w(new pending)
    end

    def failed_statuses
      %w(failed aborted canceled)
    end

    def finished_statuses
      %w(successful failed warning aborted canceled)
    end

    def human_name(_options = {})
      I18n.t("export.#{name.demodulize.underscore}")
    end
    alias human_type human_name

    def mailer_name
      'ExportMailer'
    end
  end

  def code_space
    return nil unless workgroup && exported_code_space

    @code_space ||= workgroup.code_spaces.find_by(id: exported_code_space)
  end

  def public_code_space
    @public_code_space ||= workgroup.code_spaces.public if workgroup
  end

  def export_scope_options
    { date_range: date_range, line_ids: line_ids, export_id: id }
  end

  def build_export_scope
    Export::Scope.build(referential, export_scope_options)
  end

  def export_scope
    @export_scope ||= build_export_scope
  end
  attr_writer :export_scope

  def code_provider
    @code_provider ||= Export::CodeProvider.new export_scope, code_space: code_space
  end

  def human_name
    self.class.human_name(options)
  end
  alias human_type human_name

  def successful!
    update_columns status: :successful, ended_at: Time.now
  end

  def failed!
    update_columns status: :failed, ended_at: Time.now
  end

  def notify_publication
    return false unless finished?
    return false if notified_parent_at
    return false unless publication.present?

    update_column :notified_parent_at, Time.now
    publication&.child_change
    true
  end

  def self.model_name
    ActiveModel::Name.new Export::Base, Export::Base, 'Export'
  end

  def self.user_visible_descendants
    [Export::Gtfs, Export::NetexGeneric, Export::Netex].select(&:user_visible?)
  end

  def self.user_visible?
    true
  end

  # Returns all attributes of the export file from the user point of view
  def user_file
    Chouette::UserFile.new basename: name.parameterize, extension: file_extension, content_type: content_type
  end

  # Expected and used file content type
  # Can be overrided by sub classes
  def content_type
    'application/zip'
  end

  def finished?
    self.class.finished_statuses.include?(status)
  end

  def successful?
    status.to_s == "successful"
  end

  def failed?
    self.class.failed_statuses.include?(status)
  end

  def warning?
    status.to_s == "warning"
  end

  # Use to serialize option (But why here??)
  #  Example : option :line_ids, serialize: :map_ids
  def map_ids ids
    ids&.map(&:to_i)
  end

  def workbench_for_notifications
    workbench || referential.workbench || referential.workgroup&.owner_workbench
  end

  protected

  # Expected and used file extension
  # Can be overrided by sub classes
  def file_extension
    'zip'
  end

  private

  def type_is_valid
    unless workgroup.export_types.include?(type)
    end
  end

  # Call IEV to delete when Export::Netex is deleted
  def call_iev_callback
    return if self.class.finished_statuses.include?(status)
    threaded_call_boiv_iev
  end

  def threaded_call_boiv_iev
    return if Rails.env.test?
    Thread.new(&method(:call_boiv_iev))
  end

  def call_boiv_iev
    Rails.logger.error("Begin IEV call for import")

    # Java code expects tasks in NEW status
    # Don't change status before calling iev

    Net::HTTP.get iev_callback_url
    Rails.logger.error("End IEV call for import")
  rescue Exception => e
    aborted!
    referential&.failed!
    Chouette::Safe.capture "IEV server error", e
  end

end
