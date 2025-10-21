module TomTom
  # Given some coordinates, call the TomTom Routing API to calculate a route
  # From the returned coordinates we build a geojson feature object (line string)
  class BuildLineStringFeature < ApplicationService
    TOMTOM_API_KEY = ::Chouette::Config.tomtom_api_key

    def initialize coordinates, name = ''
      @coordinates = coordinates
      @name = name
    end

    def call
      url = "https://api.tomtom.com/routing/1/calculateRoute/#{locations}/json?routeType=fastest&traffic=false&travelMode=bus&key=#{TOMTOM_API_KEY}"

      raw_response = Net::HTTP.get(URI(url))
      response = JSON.parse(raw_response)
      
      new_coordinates = response['routes'].first['legs'].flat_map { |leg| leg['points'].flat_map { |point| [ point.values_at("longitude", "latitude") ] } }

      {
        type: 'Feature',
        geometry: {
          type: 'LineString',
          coordinates: new_coordinates
        },
        properties: {
          name: @name
        }
      }
    end

    private

    def locations
      @coordinates.filter_map { |(lng, lat)| lat && lng ? "#{lat},#{lng}" : nil }.join(':')
    end
  end
end
