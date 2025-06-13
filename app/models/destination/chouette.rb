# frozen_string_literal: true

class Destination
  class Chouette < ::Destination
    option :workbench_id
    option :workbench_api_key, type: :password
    option :automatic_merge, type: :boolean, default_value: true
    option :host_type, type: :select,
                       enumerize: %w[chouette iboo custom],
                       features: { 'custom' => :destination_chouette_custom },
                       default_value: 'chouette'
    option :custom_url

    validates :workbench_id, :workbench_api_key, presence: true
    validates :custom_url, presence: true, url: true, if: proc { |d| d.host_type == 'custom' }

    CHOUETTE_URL = 'https://chouette.enroute.mobi'
    IBOO_URL = 'https://iboo.iledefrance-mobilites.fr'

    def url
      return CHOUETTE_URL if host_type == 'chouette'
      return IBOO_URL if host_type == 'iboo'

      custom_url
    end

    def import_url
      "#{url}/api/v1/workbenches/#{workbench_id}/imports"
    end

    def archive_on_fail
      automatic_merge
    end

    def transmit_export_file(_publication, report, export) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      http_request = HttpRequest.new(report, 'Chouette', import_url, response_content_type: 'application/json')

      http_request.request['Authorization'] = "Token token=#{workbench_api_key}"

      http_request.request_body = [
        ['workbench_import[name]', name],
        ['workbench_import[file]', export.file.file.to_file],
        ['workbench_import[options][automatic_merge]', automatic_merge.to_s],
        ['workbench_import[options][archive_on_fail]', archive_on_fail.to_s]
      ]

      http_request.call do |import_status|
        if import_status['status'] == 'error' && !import_status['messages'].empty?
          report_api_errors!(import_status['messages'])
        end
      end
    end
  end
end
