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
      @response ||= JSON.parse(Net::HTTP.get(URI(url)))
    end

    def url
      raise 'Not Yet Implemented'
    end

    mattr_accessor :api_key, default: Rails.application.secrets.tomtom_api_key
  end
end
