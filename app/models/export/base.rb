require 'net/http/post/multipart'

class Export::Base < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  self.table_name = "exports"

  belongs_to :referential

  validates :type, :referential_id, presence: true

  def self.messages_class_name
    "Export::Message"
  end

  def self.resources_class_name
    "Export::Resource"
  end

  def self.human_name
    I18n.t("export.#{self.name.demodulize.underscore}")
  end

  def self.file_extension_whitelist
    %w(zip csv json)
  end

  def has_metadata?
    false
  end

  def upload_file file
    url = URI.parse upload_workbench_export_url(self.workbench_id, self.id, host: Rails.application.config.rails_host)
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

  def self.option name, opts={}
    store_accessor :options, name

    if opts[:serialize]
      define_method name do
        val = options.stringify_keys[name.to_s]
        unless val.is_a? opts[:serialize]
          val = JSON.parse(val) rescue opts[:serialize].new
        end
        val
      end
    end

    if !!opts[:required]
      if opts[:depends]
        validates name, presence: true, if: ->(record){ record.send(opts[:depends][:option]) == opts[:depends][:value]}
      else
        validates name, presence: true
      end
    end
    @options ||= {}
    @options[name] = opts

    if block_given?
      yield Export::OptionProxy.new(self, opts.update(name: name))
    end
  end

  def self.options
    @options ||= {}
  end

  def self.options= options
    @options = options
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

  def visible_options
    options.select{|k, v| ! k.match  /^_/}
  end

  def display_option_value option_name, context
    option = self.class.options[option_name.to_sym]
    val = self.options[option_name.to_s]
    if option[:display]
      context.instance_exec(val, &option[:display])
    else
      val
    end
  end

  private

  def initialize_fields
    super
    self.token_upload = SecureRandom.urlsafe_base64
  end

end
