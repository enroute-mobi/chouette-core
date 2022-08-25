# frozen_string_literal: true

# Create Shape from given points
module RoutePlanner
  # Use TomTom Routing API to create shape
  class TomTom
    include Measurable

    def shape(points)
      Request.new(points).shape
    end
    measure :shape

    # Performs a Request to the TomTom Routing API
    class Request < ::TomTom::Request
      def initialize(points)
        super()
        @points = points
      end
      attr_reader :points

      def shape
        Rails.logger.debug { "Invoke TomTom Routing API for #{points.size} points" }
        tomtom_linestring
      rescue StandardError => e
        Chouette::Safe.capture "Can't read TomTom Routing API response", e
        nil
      end

      def tomtom_points
        response['routes'].first['legs'].flat_map do |leg|
          leg['points'].flat_map do |point|
            longitude, latitude = point.values_at('longitude', 'latitude')
            rgeo_factory.point(longitude, latitude)
          end
        end
      end

      def tomtom_linestring
        rgeo_factory.line_string(tomtom_points)
      end

      private

      def rgeo_factory
        @rgeo_factory ||= RGeo::Geos.factory srid: 4326
      end

      def locations
        points.map { |point| "#{point.latitude},#{point.longitude}" }.join(':')
      end

      def url
        [
          "https://api.tomtom.com/routing/1/calculateRoute/#{locations}/",
          "json?routeType=fastest&traffic=false&travelMode=bus&key=#{api_key}"
        ].join
      end
    end
  end

  # Keep in cache shapes created by another instance
  class Cache
    include Measurable

    def initialize(next_instance)
      @next_instance = next_instance
    end
    attr_reader :next_instance

    def shape(points)
      Rails.cache.fetch(rounded_points(points), skip_nil: true, expires_in: time_to_live) do
        next_instance.shape(points)
      end
    end
    measure :shape

    mattr_accessor :time_to_live, default: 7.days

    private

    def rounded_points(points)
      points.map { |point| "#{point.latitude.round(6)},#{point.longitude.round(6)}" }.join(':')
    end
  end

  # Returns nil
  class Null
    def shape(*)
      nil
    end
  end
end
