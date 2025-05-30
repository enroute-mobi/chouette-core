class Destination < ApplicationModel
  include OptionsSupport

  belongs_to :publication_setup, inverse_of: :destinations, optional: true # CHOUETTE-3247 failing specs
  has_many :reports, class_name: 'DestinationReport', dependent: :destroy

  validates :name, :type, presence: true

  mount_uploader :secret_file, SecretFileUploader
  validates :secret_file, presence: true, if: :secret_file_required?

  @secret_file_required = false

  class << self
    def secret_file_required?
      !!@secret_file_required
    end
  end

  def secret_file_required?
    self.class.secret_file_required?
  end

  def transmit(publication)
    report = reports.find_or_create_by(publication_id: publication.id)
    report.start!
    begin
      transmit_export(publication, report)
      report.success! unless report.failed?
    rescue StandardError => e
      ::Chouette::Safe.capture "Destination ##{id} transmission failed for Publication #{publication.id}", e
      report.failed! message: e.message, backtrace: e.backtrace
    end
  end

  def transmit_export(publication, report)
    secret_file.cache! if secret_file_required?

    export = publication.export
    return unless export
    return if export[:file].blank?

    Rails.logger.tagged("#{self.class.name} ##{id}") do
      export.file.cache_stored_file!
      transmit_export_file(publication, report, export)
    end
  end

  def transmit_export_file(report, file)
    raise NotImplementedError
  end

  def human_type
    self.class.human_type
  end

  def self.human_type
    ts
  end

  class HttpRequest
    def initialize(
      report,
      name,
      uri_s,
      request_content_type: 'multipart/form-data',
      response_content_type: 'application/json'
    )
      @report = report
      @name = name
      @uri = URI(uri_s)
      @request_content_type = request_content_type
      @response_content_type = response_content_type
    end
    attr_reader :report, :name, :uri, :request_content_type, :response_content_type

    def logger
      Rails.logger
    end

    def request
      @request ||= Net::HTTP::Post.new(uri)
    end

    def request_body=(data)
      case request_content_type
      when 'multipart/form-data'
        request.set_form(data, 'multipart/form-data')
      when 'application/json'
        request.body = data.to_json
      else
        request.body = data
      end
    end

    def response # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      return @response if defined?(@response)

      logger.info("Send file to #{name} on #{uri}")

      response ||= Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?) do |http|
        http.request(request)
      end

      logger.info("#{name} response #{response.code} #{response.body.truncate(256)}")

      if response.is_a?(Net::HTTPSuccess) && response.content_type == response_content_type
        @success = true
      else
        report.failed!(message: "Unexpected response from #{name} API: #{response.code}")
        @success = false
      end

      @response = response
    end

    def response_content
      case response_content_type
      when 'application/json'
        JSON.parse(response.body)
      else
        response.body
      end
    end

    def call
      response
      yield response_content if block_given? && @success
    end

    def report_api_errors!(errors)
      report.failed!(message: "Errors returned by #{name} API: #{errors.inspect}")
    end

    private

    def use_ssl?
      uri.instance_of?(URI::HTTPS)
    end
  end
end
