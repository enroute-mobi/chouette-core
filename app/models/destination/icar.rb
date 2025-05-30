# frozen_string_literal: true

class Destination
  class Icar < ::Destination
    option :icar_token, type: :password

    validates :icar_token, presence: true

    def icar_import_url
      @icar_import_url ||= ENV['ICAR_IMPORT_URL'] || 'https://icar.iledefrance-mobilites.fr/api/v1/imports'
    end

    def transmit_export_file(_publication, report, export)
      http_request = HttpRequest.new(report, 'ICAR', icar_import_url, request_content_type: 'application/json')

      http_request.request['Authorization'] = "Bearer #{icar_token}"

      http_request.request_body = {
        'nomFichier' => File.basename(export.file.filename),
        'content' => Base64.encode64(export.file.read)
      }

      http_request.call
    end
  end
end
