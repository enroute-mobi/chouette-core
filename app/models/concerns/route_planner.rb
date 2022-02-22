module RoutePlanner
  class TomTom
    attr_accessor :points

    def initialize(points)
      @points = points
    end

    def shape
      begin
        response = JSON.parse(open(url).read)
        tomtom_points = response['routes'].first['legs'].flat_map do |leg|
          leg['points'].flat_map do |point|
            longitude, latitude = point.values_at("longitude", "latitude")
            rgeo_factory.point(longitude, latitude)
          end
        end

        return rgeo_factory.line_string(tomtom_points)
      rescue => e
        Chouette::Safe.capture "Something goes wrong in TomTom API", e
        return nil
      end
    end

    private

    def rgeo_factory
      @rgeo_factory ||= RGeo::Geos.factory srid: 4326
    end

    def locations
      points.map { |point| "#{point.latitude},#{point.longitude}" }.join(':')
    end

    def url
      "#{CALCULATE_ROUTE_URL}/#{locations}/json?routeType=fastest&traffic=false&travelMode=bus&key=#{API_KEY}"
    end

    CALCULATE_ROUTE_URL = Rails.application.secrets.tomtom_calculate_route_url
    API_KEY = Rails.application.secrets.tomtom_api_key
  end

  class Cache
    def shape(points)
      Rails.cache.fetch(rounded_points(points)) do
        TomTom.new(points).shape
      end
    end

    private

    def rounded_points(points)
      points.map { |point| "#{point.latitude.round(6)},#{point.longitude.round(6)}" }.join(':')
    end
  end

  class Null
    def shape(*)
      nil
    end
  end
end