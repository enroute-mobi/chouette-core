class ShapeEditorController < ApplicationController
  def home
  end

  def get_waypoints
    render xml: File.read(Rails.root.join('tomtom.kml'))
  end

  def update_line
    coordinates = JSON.parse(request.raw_post).fetch('coordinates')
    query = coordinates.map { |(longitude, latitude)| "#{latitude},#{longitude}" }.join(':')

    key = ENV["TOMTOM_API_KEY"]

    url = "https://api.tomtom.com/routing/1/calculateRoute/#{query}/json?routeType=fastest&traffic=false&travelMode=bus&key=#{key}"

    raw_response = open(url).read
    response = JSON.parse(raw_response)
    new_coordinates = response['routes'].first['legs'].flat_map { |leg| leg['points'].flat_map { |point| [ point.values_at("longitude", "latitude") ] } }

    render json: { type: 'Feature', geometry: { type: 'LineString', coordinates: new_coordinates } }
  end
end
