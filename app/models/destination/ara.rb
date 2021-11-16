class Destination::Ara < ::Destination
  option :ara_url
  option :credentials

  validates :ara_url, presence: true
  validates :credentials, presence: true

  def do_transmit(publication, report)
    Rails.logger.tagged("Destination::Ara ##{id}") do
      publication.exports.each do |export|
        send_to_ara export.file, report if export[:file]
      end
    end
  end

  def ara_import_url
    "#{ara_url}/import"
  end

  def send_to_ara(file, report)
    payload = { "force": true }
    uri = URI(ara_import_url)

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Token token=#{credentials}"

    local_file = local_temp_file(file)
    form_data = [['request', payload.to_json], ['data', local_file]]
    request.set_form form_data, 'multipart/form-data'

    Rails.logger.info "Send file to Ara on #{ara_import_url}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    Rails.logger.info "Ara response #{response.code} #{response.body.truncate(256)}"

    if response.is_a?(Net::HTTPSuccess) && response["content-type"] == "application/json"
      import_status = JSON.parse response.body
      unless import_status["Errors"].empty?
        report.failed! "Errors returned by Ara API: #{import_status["Errors"].inspect}"
      end
    else
      report.failed! "Unexpected response from Ara API: #{response.code}"
    end
  end
end
