# frozen_string_literal: true

class Destination
  class Custom < ::Destination
    option :url
    option :workbench_id
    option :workbench_api_key
    option :automatic_merge, type: :boolean, default_value: true

    validates :url, :workbench_id, :workbench_api_key, presence: true
    validates :url, url: true

    def do_transmit(publication, report)
      Rails.logger.tagged("Destination:: ##{id}") do
        if (export = publication.export)
          export.file.cache_stored_file!
          send_to_custom export.file, report if export[:file]
        end
      end
    end

    def import_url
      "#{url}/workbenches/#{workbench_id}/imports"
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

    def send_to_custom(file, report)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Token token=#{workbench_api_key}"

      form_data = [
        ['name', name],
        ['file', file],
        ['automatic_merge', automatic_merge],
        ['archive_on_fail', archive_on_fail]
      ]
      request.set_form form_data, 'multipart/form-data'

      Rails.logger.info "Send file to custom on #{import_url}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?) do |http|
        http.request(request)
      end

      Rails.logger.info "custom response #{response.code} #{response.body.truncate(256)}"

      if response.is_a?(Net::HTTPSuccess) && response['content-type'] == 'application/json'
        import_status = JSON.parse response.body
        unless import_status['Errors'].empty?
          report.failed! message: "Errors returned by custom API: #{import_status['Errors'].inspect}"
        end
      else
        report.failed! message: "Unexpected response from custom API: #{response.code}"
      end
    end
  end
end
