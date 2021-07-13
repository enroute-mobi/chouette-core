module Shapes
  class Create < ApplicationService
    attr_reader :coordinates, :factory, :journey_pattern, :shape, :waypoints

    def initialize(waypoints: [], coordinates: [], journey_pattern:, **params)
      @waypoints = waypoints
      @coordinates = coordinates
      @journey_pattern = journey_pattern
      
      @shape = Shape.new(params)

      @factory = RGeo::Geos.factory(srid: 4326)
    end

    def call
      points = coordinates.map { |(lon, lat)| factory.point(lon, lat) }

      shape.geometry = factory.line_string(points)

      shape.transaction do
        raise ActiveRecord::Rollback unless shape.save

        waypoints.map do |w|
          shape.waypoints.create(
            name: w['name'],
            waypoint_type: w['type'],
            position: w['position'],
            coordinates: w['coordinates']
          )
        end

        journey_pattern.update(shape: shape)
      end

      shape
    end
  end
end