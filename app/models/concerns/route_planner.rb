module RoutePlanner
  class TomTom
    attr_accessor :points, :transport_mode

    def initialize(points, transport_mode)
      @points = points
      @transport_mode = transport_mode
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
      "#{route_calculation_url}/#{locations}/json?routeType=fastest&traffic=false&travelMode=#{transport_mode}&key=#{api_key}"
    end

    def api_key
      if Rails.env.test?
        "mock_tomtom_api_key"
      else
        Rails.application.secrets.tomtom_api_key
      end
    end

    def route_calculation_url
      if Rails.env.test?
        "http://mock.api.tomtom.com/calculateRoute"
      else
        Rails.application.secrets.tomtom_route_calculation_url
      end
    end
  end

  class Cache
    def shape(points, transport_mode)
      Rails.cache.fetch([rounded_points(points), transport_mode]) do
        TomTom.new(points, transport_mode).shape
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