# frozen_string_literal: true

class Destination
  class Chouette < ::Destination
    option :workbench_id
    option :workbench_api_key, type: :password
    option :automatic_merge, type: :boolean, default_value: true
    option :host_type, type: :select,
                       collection: %w[chouette iboo],
                       features: { destination_chouette_custom: %w[custom] },
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

    def do_transmit(publication, report)
      Rails.logger.tagged("Destination:: ##{id}") do
        if (export = publication.export)
          export.file.cache_stored_file!
          send_to_chouette export.file, report if export[:file]
        end
      end
    end

    def uri
      @uri ||= URI(import_url)
    end

    def use_ssl?
      uri.instance_of?(URI::HTTPS)
    end

    def archive_on_fail
      automatic_merge
    end

    def send_to_chouette(file, report)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Token token=#{workbench_api_key}"

      form_data = [
        ['workbench_import[name]', name],
        ['workbench_import[file]', file.file.to_file],
        ['workbench_import[options][automatic_merge]', automatic_merge.to_s],
        ['workbench_import[options][archive_on_fail]', archive_on_fail.to_s]
      ]
      request.set_form form_data, 'multipart/form-data'

      Rails.logger.info "Send file to Chouette on #{import_url}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?) do |http|
        http.request(request)
      end

      Rails.logger.info "Chouette response #{response.code} #{response.body.truncate(256)}"

      if response.is_a?(Net::HTTPSuccess) && response.content_type == 'application/json'
        import_status = JSON.parse response.body
        if import_status['status'] == 'error' && !import_status['messages'].empty?
          report.failed! message: "Errors returned by Chouette API: #{import_status['messages'].inspect}"
        end
      else
        report.failed! message: "Unexpected response from Chouette API: #{response.code}"
      end
    end
  end
end
