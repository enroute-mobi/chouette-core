module TomTom
  # Given some coordinates, call the TomTom Routing API to calculate a route
  # From the returned coordinates we build a geojson feature object (line string)
  class BuildLineStringFeature < ApplicationService
    TOMTOM_API_KEY = Rails.application.secrets.tomtom_api_key

    def initialize coordinates
      @coordinates = coordinates
    end

    def call
      url = "https://api.tomtom.com/routing/1/calculateRoute/#{locations}/json?routeType=fastest&traffic=false&travelMode=bus&key=#{TOMTOM_API_KEY}"

      raw_response = open(url).read
      response = JSON.parse(raw_response)
      
      new_coordinates = response['routes'].first['legs'].flat_map { |leg| leg['points'].flat_map { |point| [ point.values_at("longitude", "latitude") ] } }

      {
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates: new_coordinates
        },
        crs: {
          type: 'name',
          properties: {
            name: 'EPSG:3857',
          }
        }
      }
    end

    private

    def locations
      @coordinates.map { |(longitude, latitude)| "#{latitude},#{longitude}" }.join(':')
    end
  end
end