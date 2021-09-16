require 'net/http/post/multipart'

class Export::Base < ApplicationModel
  self.table_name = "exports"

  # Normally with this code i18n translation is possible with Export::Base.last.profile_text or Export::Base.last.profile.text
  # But actually it fails with undefined method `text' for "european":String
  # extend Enumerize
  # extend ActiveModel::Naming

  include Rails.application.routes.url_helpers
  include OptionsSupport
  include NotifiableSupport
  include PurgeableResource

  def self.mailer_name
    'ExportMailer'
  end

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

  def file_extension_whitelist
    %w(zip csv json)
  end

  class << self
    # Those two methods are defined here because they are required to include IevInterfaces::Task
    def messages_class_name
      "Export::Message"
    end

    def resources_class_name
      "Export::Resource"
    end

    def human_name(options={})
      I18n.t("export.#{self.name.demodulize.underscore}")
    end

    alias_method :human_type, :human_name
  end

  include IevInterfaces::Task

  belongs_to :referential
  belongs_to :publication
  belongs_to :workgroup, class_name: '::Workgroup'

  has_many :publication_api_sources, foreign_key: :export_id

  validates :type, presence: true, inclusion: { in: Proc.new { |e| e.workgroup&.export_types || ::Workgroup::DEFAULT_EXPORT_TYPES } }

  validates_presence_of :workgroup, :referential_id
  validates :options, export_options: true

  after_create :purge_exports
  def purge_exports
    return unless workbench.present?

    workbench.exports.file_purgeable.each do |exp|
      exp.update(remove_file: true)
    end
    workbench.exports.purgeable.destroy_all
  end

  before_save :resolve_line_ids
  def resolve_line_ids
    return unless self.respond_to?(:line_ids) # To delete when java export is disabled
    return unless self.line_ids.nil? # Useless to update line_ids if line_ids exists
    options = Export::Scope::Options.new(referential, date_range: date_range, line_ids: line_ids, line_provider_ids: line_provider_ids, company_ids: company_ids)
    self.line_ids = options.line_ids
  end

  attr_accessor :synchronous

  scope :not_used_by_publication_apis, -> {
    joins('LEFT JOIN public.publication_api_sources ON publication_api_sources.export_id = exports.id')
    .where("publication_api_sources.id IS NULL")
  }
  scope :purgeable, -> {
    not_used_by_publication_apis.where("exports.created_at <= ?", clean_after.days.ago)
  }

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
  alias_method :human_type, :human_name

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
    update status: 'failed'
    notify_state
    raise
  end

  def upload_file file

    # FIXME See CHOUETTE-207
    url = if workbench.present?
      URI.parse upload_workbench_export_url(self.workbench_id, self.id, host: Rails.application.config.rails_host)
    else
      URI.parse upload_export_url(self.id, host: Rails.application.config.rails_host)
    end
    res = nil
    filename = File.basename(file.path)
    content_type = MIME::Types.type_for(filename).first&.content_type
    File.open(file.path) do |file_content|
      req = Net::HTTP::Post::Multipart.new(url.path, file: UploadIO.new(file_content, content_type, filename), token: self.token_upload, max_retries: 3)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
    end
    res
  end

  def self.model_name
    ActiveModel::Name.new Export::Base, Export::Base, "Export"
  end

  def self.user_visible_descendants
    [Export::Gtfs, Export::NetexGeneric, Export::Netex].select &:user_visible?
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

  # TODO Should be shared in Operation
  def successful?
    status.to_s == "successful"
  end

  protected

  # Expected and used file extension
  # Can be overrided by sub classes
  def file_extension
    "zip"
  end

  private

  def type_is_valid
    unless workgroup.export_types.include?(type)
    end
  end

  def initialize_fields
    super
    self.token_upload = SecureRandom.urlsafe_base64
  end

  def map_ids ids
    ids&.map(&:to_i)
  end
end
