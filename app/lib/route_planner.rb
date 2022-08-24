# frozen_string_literal: true

# Create Shape from given points
module RoutePlanner
  # Use TomTom Routing API to create shape
  class TomTom
    def shape(points)
      Request.new(points).shape
    end

    # Performs a Request to the TomTom Routing API
    class Request
      def initialize(points)
        @points = points
      end
      attr_accessor :points

      def shape
        tomtom_linestring
      rescue StandardError => e
        Chouette::Safe.capture "Can't read TomTom Routing API response", e
        nil
      end

      def response
        @response ||= JSON.parse(Net::HTTP.get(URI(url)))
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

      mattr_accessor :api_key, default: Rails.application.secrets.tomtom_api_key
    end
  end

  # Keep in cache shapes created by another instance
  class Cache
    def initialize(next_instance)
      @next_instance = next_instance
    end
    attr_reader :next_instance

    def shape(points)
      Rails.cache.fetch(rounded_points(points)) do
        next_instance.shape(points)
      end
    end

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
