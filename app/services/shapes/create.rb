module Shapes
  class Create < ApplicationService
    attr_reader :journey_pattern, :waypoints

    def initialize(waypoints: [], coordinates: [], journey_pattern:, **params)
      @waypoints = waypoints
      @journey_pattern = journey_pattern
      
      factory = RGeo::Geos.factory(srid: 4326)

      shape.update_attributes(params)
      points = coordinates.map { |(lon, lat)| factory.point(lon, lat) }
      shape.geometry = factory.line_string(points)
    end

    def call
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

    private

    def shape
      @shape ||= Shape.new
    end
  end
end