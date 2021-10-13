module Shapes
  class Create < ApplicationService
    attr_reader :geometry, :journey_pattern, :params, :waypoints_attributes

    def initialize(waypoints: [], coordinates: [], journey_pattern:, **params)
      @waypoints_attributes = waypoints.map(&:symbolize_keys)
      @journey_pattern = journey_pattern
      @params = params

      factory = RGeo::Geos.factory(srid: 4326)
      points = coordinates.map { |(lon, lat)| factory.point(lon, lat) }
      
      @geometry = factory.line_string(points)
    end

    def call
      shape.transaction do
        yield if block_given?

        shape.assign_attributes(**params, geometry: geometry)

        shape.waypoints.build(waypoints_attributes)

        ShapeValidator.new.validate!(shape)

        shape.save!
        journey_pattern.update!(shape: shape)

        shape
      rescue => e
        Rails.logger.debug e.inspect
        raise ActiveRecord::Rollback
        shape
      end
    end

    private

    def shape
      @shape ||= Shape.new
    end
  end
end