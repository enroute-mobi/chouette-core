module TomTom
  BASE_URL = 'https://api.tomtom.com'

  @@api_key = Rails.application.secrets.tomtom_api_key
  cattr_accessor :api_key

  def self.connection
    @connection ||= Faraday.new(
      url: BASE_URL,
      params: {
        key: api_key
      }
    ) do |faraday|
      faraday.use FaradayMiddleware::FollowRedirects, limit: 1
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.enabled?
    api_key.present? && /[a-zA-Z0-9]{32}/ === api_key
  end

  @@instance = TomTom::Minimum.new(TomTom::Cache.new(TomTom::Batch.new(connection)))
  def self.evaluate(way_costs)
    @@instance.evaluate way_costs
  end

  def self.batch(way_costs)
    TomTom::Batch.new(connection).batch(way_costs)
  end

  def self.matrix(way_costs)
    TomTom::Cache.new(connection).matrix(way_costs)
  end

  # Base class to create TomTom API Request
  class Request
    def response
      @response ||= JSON.parse(call_api(url))
    end

    def url
      raise 'Not Yet Implemented'
    end

    def call_api(url, options = {})
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      case options[:type]
      when /POST/i
        request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
        request.body = options[:body]
        http.request(request)
      else # GET
        Net::HTTP.get(uri)
      end
    end

    mattr_accessor :api_key, default: Rails.application.secrets.tomtom_api_key
  end
end
