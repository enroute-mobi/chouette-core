require 'net/http/post/multipart'

class Export::Base < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include OptionsSupport
  include NotifiableSupport
  include PurgeableResource

  self.table_name = "exports"

  belongs_to :referential
  belongs_to :publication

  has_many :publication_api_sources, foreign_key: :export_id

  validates :type, :referential_id, presence: true

  after_create :purge_exports
  after_commit :notify_state
  attr_accessor :synchronous

  scope :not_used_by_publication_apis, -> {
    joins('LEFT JOIN public.publication_api_sources ON publication_api_sources.export_id = exports.id')
    .where("publication_api_sources.id IS NULL")
  }
  scope :purgeable, -> {
    not_used_by_publication_apis.where("exports.created_at <= ?", clean_after.days.ago)
  }

  class << self
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

    def file_extension_whitelist
      %w(zip csv json)
    end
  end

  def human_name
    self.class.human_name(options)
  end
  alias_method :human_type, :human_name

  def run
    update status: 'running', started_at: Time.now
    export
  rescue Exception => e
    Rails.logger.error e.message

    messages.create(criticity: :error, message_attributes: { text: e.message }, message_key: :full_text)
    update status: 'failed'
    raise
  end

  def notify_state
    payload = self.slice(:id, :status, :name, :parent_id)
    payload.update({
      status_html: import_status(self.status).html_safe,
      message_key: "#{self.class.name.underscore.gsub('/', '.')}.#{self.status}",
      url: polymorphic_url([self.referential.workbench, self], only_path: true),
      unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}"
    })

    if self.class < Export::Base
      payload[:fragment] = "export-fragment"
    end
    Notification.create! channel: referential.workbench.notifications_channel, payload: payload
  end

  def notify_child_progress child, progress
    index = self.children.index child
    notify_progress (index+progress)/self.children.count
  end

  def notify_progress progress
    @previous_progress ||= 0
    return unless progress - @previous_progress >= 0.01
    @previous_progress = progress
    if parent
      parent.notify_child_progress self, progress
    else
      payload = self.slice(:id, :status, :name, :parent_id)
      payload.update({
        message_key: "#{self.class.name.underscore.gsub('/', '.')}.progress",
        status_html: import_status(self.status).html_safe,
        url: polymorphic_url([self.referential.workbench, self], only_path: true),
        unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}",
        progress: (progress*100).to_i
      })
      Notification.create! channel: referential.workbench.notifications_channel, payload: payload
    end
  end

  def purge_exports
    return unless workbench.present?

    workbench.exports.file_purgeable.each do |exp|
      exp.update(remove_file: true)
    end
    workbench.exports.purgeable.destroy_all
  end

  def upload_file file

    url = if workbench.present?
      URI.parse upload_workbench_export_url(self.workbench_id, self.id, host: Rails.application.config.rails_host)
    else
      URI.parse upload_export_url(self.id, host: Rails.application.config.rails_host)
    end
    res = nil
    filename = File.basename(file.path)
    content_type = MIME::Types.type_for(filename).first&.content_type
    File.open(file.path) do |file_content|
      req = Net::HTTP::Post::Multipart.new url.path,
        file: UploadIO.new(file_content, content_type, filename),
        token: self.token_upload
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
    end
    res
  end

  if Rails.env.development?
    def self.force_load_descendants
      path = Rails.root.join 'app/models/export'
      Dir.chdir path do
        Dir['**/*.rb'].each do |src|
          next if src =~ /^base/
          klass_name = "Export::#{src[0..-4].camelize}"
          Rails.logger.info "Loading #{klass_name}"
          begin
            klass_name.constantize
          rescue => e
            Rails.logger.info "Failed: #{e.message}".red
            nil
          end
        end
      end
    end
  end

  def self.user_visible?
    false
  end

  def self.inherited child
    super child
    child.instance_eval do
      def self.user_visible?
        true
      end
    end
  end

  include IevInterfaces::Task

  def self.model_name
    ActiveModel::Name.new Export::Base, Export::Base, "Export"
  end

  def self.user_visible_descendants
    descendants.select &:user_visible?
  end

  def self.user_visible?
    true
  end

  private

  def initialize_fields
    super
    self.token_upload = SecureRandom.urlsafe_base64
  end
end
