# frozen_string_literal: true

class Destination
  class Icar < ::Destination
    option :icar_type, enumerize: %w[production custom], default_value: 'production'
    option :custom_icar_url, type: :string
    option :site_id, type: :string
    option :site_name, type: :string
    option :file_type, enumerize: %w[T P]
    option :icar_token, type: :password

    validates :icar_token, presence: true
    validates :custom_icar_url, presence: true, if: :custom_type?

    def custom_type?
      icar_type == 'custom'
    end

    def icar_import_url
      return custom_icar_url if custom_type? && custom_icar_url.present?

      @icar_import_url ||= ENV['ICAR_IMPORT_URL'] || 'https://icar.iledefrance-mobilites.fr/api/v1/imports'
    end

    def transmit_export_file(_publication, report, export) # rubocop:disable Metrics/MethodLength
      http_request = HttpRequest.new(
        report: report,
        name: 'ICAR',
        uri: icar_import_url,
        request_content_type: 'application/json'
      )

      http_request.request['Authorization'] = "Bearer #{icar_token}"

      http_request.request_body = {
        'nomFichier' => icar_api_filename,
        'content' => Base64.encode64(export.file.read)
      }

      http_request.call
    end

    private

    def icar_api_filename
      "ARRET_#{site_id}_#{site_name}_#{file_type}_#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}.zip"
    end
  end
end
