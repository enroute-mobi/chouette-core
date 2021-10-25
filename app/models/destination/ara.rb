if ::Destination.enabled?("ara")
  class Destination::Ara < ::Destination
    option :ara_url
    option :credentials

    validates :ara_url, presence: true
    validates :credentials, presence: true

    @secret_file_required = true

    def do_transmit(publication, report)
      publication.exports.each do |export|
        send_to_ara export.file if export[:file]
      end
    end

    def send_to_ara file
      connection = Faraday.new(
          url: ara_url,
          headers: {'Content-Type' => 'application/json', Authorization: "Token token=#{credentials}" }
        ) do |conn|
          conn.request :multipart
          conn.response :json, content_type: /\bjson$/
          conn.use Faraday::Response::RaiseError
          conn.adapter Faraday.default_adapter

          conn.use BadRequestMiddlewareParser
      end

      payload = { request: '{"force": true}' }
      payload[:data] = Faraday::FilePart.new(file, 'text/csv')

      connection.post('/', payload)
    end

    class BadRequestMiddlewareParser < Faraday::Response::Middleware
      def on_complete(env)
        return env unless env.response.status == 400

        env.body = parse(env.body)
      end

      def parse(body)
        JSON.parse(body)['Errors'].transform_keys(&:underscore)
      end
    end
  end
end
