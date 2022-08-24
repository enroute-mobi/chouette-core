module Macro
  class CreateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_each do |journey_pattern|
          factory = ShapeFactory.new(journey_pattern, workgroup, shape_provider)
          next unless factory.waypoints

          shape_id = shape_cache[factory.stop_area_ids] || factory.shape&.id
          journey_pattern.update shape_id: shape_id if shape_id
        end
      end

      class ShapeFactory
        def initialize(journey_pattern, workgroup, shape_provider)
          @journey_pattern = journey_pattern
          @workgroup = workgroup
          @shape_provider = shape_provider
        end
        attr_accessor :journey_pattern, :workgroup, :shape_provider

        def waypoints
          @waypoints ||= journey_pattern.waypoints
        end

        def shape
          return unless waypoints && geometry

          shape_provider.shapes.create!(
            name: shape_name,
            waypoints: waypoints,
            geometry: geometry
          )
        end

        def shape_name
          [journey_pattern.registration_number, journey_pattern.name].select(&:present?).join(' - ')
        end

        def geometry
          @geometry ||= workgroup.route_planner.shape(waypoints)
        end

        def stop_area_ids
          @stop_area_ids ||=
            journey_pattern.stop_points.map { |stop_point| stop_point.stop_area&.id }
        end
      end

      def shape_cache
        @shape_cache ||= {}
      end

      def journey_patterns
        scope.journey_patterns.without_associated_shape.includes(stop_points: :stop_area)
      end

      def shape_provider
        @shape_provider ||= workbench.shape_providers.first
      end
    end
  end
end
