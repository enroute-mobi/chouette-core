require 'net/http/post/multipart'

class Export::Base < ApplicationModel
  self.table_name = 'exports'
  # Normally with this code i18n translation is possible with Export::Base.last.profile_text or Export::Base.last.profile.text
  # But actually it fails with undefined method `text' for "european":String
  include Rails.application.routes.url_helpers
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
    self.token_upload = SecureRandom.urlsafe_base64
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

  def self.mailer_name
    'ExportMailer'
  end

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
  end

  def code_space
    # User option in the future
    @code_space ||= workgroup.code_spaces.default if workgroup
  end

  def public_code_space
    @public_code_space ||= workgroup.code_spaces.public if workgroup
  end

  def export_scope
    @export_scope ||= Export::Scope.build(referential, date_range: date_range, line_ids: line_ids)
  end
  attr_writer :export_scope

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

  def notify_parent
    return false unless finished?
    return false if notified_parent_at

    return false unless publication.present?

    update_column :notified_parent_at, Time.now

    publication&.child_change

    true
  end

  def run
    update status: 'running', started_at: Time.now
    export
    notify_state unless publication.present?
  rescue Exception => e
    Chouette::Safe.capture "Export ##{id} failed", e

    messages.create(criticity: :error, message_attributes: { text: e.message }, message_key: :full_text)
    self.update status: :failed, ended_at: Time.now
    notify_state
    raise
  end

  def upload_file(file)
    # FIXME: See CHOUETTE-207
    url = if workbench.present?
            URI.parse upload_workbench_export_url(workbench_id, id, host: Rails.application.config.rails_host)
          else
            URI.parse upload_export_url(id, host: Rails.application.config.rails_host)
          end
    res = nil
    filename = File.basename(file.path)
    content_type = MIME::Types.type_for(filename).first&.content_type
    File.open(file.path) do |file_content|
      req = Net::HTTP::Post::Multipart.new(url.path, file: UploadIO.new(file_content, content_type, filename),
                                                     token: token_upload, max_retries: 3)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
    end
    res
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

  #
  # Notification
  #
  def workbench_for_notifications
    workbench || referential.workbench || referential.workgroup&.owner_workbench
  end

  def url_for_notifications
    [workbench_for_notifications, self]
  end

  def urls_to_refresh
    [polymorphic_url(self.url_for_notifications, only_path: true)]
  end

  def notify_state
    payload = self.slice(:id, :status, :name)
    payload.update({
      status_html: operation_status(self.status).html_safe,
      message_key: "#{self.class.name.underscore.gsub('/', '.')}.#{self.status}",
      url: polymorphic_url(url_for_notifications, only_path: true),
      urls_to_refresh: urls_to_refresh,
      unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}"
    })

    payload[:fragment] = "export-fragment"
    Notification.create! channel: workbench_for_notifications.notifications_channel, payload: payload
  end

  def notify_progress progress
    # Prevent export notification when export is launched by a publication
    return if (self.class < Export::Base && self.publication.present?)
    @previous_progress ||= 0
    return unless progress - @previous_progress >= 0.01
    @previous_progress = progress

    payload = self.slice(:id, :status, :name)
    payload.update({
      message_key: "#{self.class.name.underscore.gsub('/', '.')}.progress",
      status_html: operation_status(self.status).html_safe,
      url: polymorphic_url(url_for_notifications, only_path: true),
      urls_to_refresh: urls_to_refresh,
      unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}",
      progress: (progress*100).to_i
    })
    Notification.create! channel: workbench_for_notifications.notifications_channel, payload: payload

  end

  def operation_progress_weight
    1
  end

  def operations_progress_total_weight
    steps_count
  end

  def operation_relative_progress_weight(operation_name)
    operation_progress_weight.to_f/operations_progress_total_weight
  end

  def notify_operation_progress(operation_name)
    if @progress
      @progress += operation_relative_progress_weight(operation_name)
      notify_progress @progress
    end
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
