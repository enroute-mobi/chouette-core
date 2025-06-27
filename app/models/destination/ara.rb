# frozen_string_literal: true

class Destination
  class Ara < ::Destination
    option :ara_url
    option :credentials
    option :force_import, type: :boolean, default_value: true

    validates :ara_url, presence: true
    validates :credentials, presence: true

    def ara_import_url
      "#{ara_url}/import"
    end

    def transmit_export_file(_publication, report, export) # rubocop:disable Metrics/MethodLength
      http_request = HttpRequest.new(
        report: report,
        name: 'Ara',
        uri: ara_import_url,
        response_content_type: 'application/json'
      )

      http_request.request['Authorization'] = "Token token=#{credentials}"

      payload = { "force": force_import }
      form_data = [['request', payload.to_json], ['data', export.file]]
      http_request.request_body = form_data

      http_request.call do |import_status|
        http_request.report_api_errors!(import_status['Errors']) unless import_status['Errors'].empty?
      end
    end
  end
end
