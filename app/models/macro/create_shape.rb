module Macro
  class CreateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_each do |journey_pattern|
          next unless journey_pattern.waypoints

          factory = ShapeFactory.new(journey_pattern, workgroup, shape_provider)

          unless shape_id = shape_cache[factory.stop_area_ids]
            journey_pattern.update shape_id: shape_id
          else
            shape = factory.shape
            shape_cache[factory.stop_area_ids] = shape.id
          end
        end
      end

      class ShapeFactory
        def initialize(journey_pattern, workgroup, shape_provider)
          @journey_pattern = journey_pattern
          @workgroup = workgroup
          @shape_provider = shape_provider
        end
        attr_accessor :journey_pattern, :workgroup, :shape_provider

        delegate :waypoints, to: :journey_pattern

        def shape
          shape_provider.shapes.create(
            name: shape_name,
            waypoints: waypoints,
            geometry: geometry
          )
        end

        def shape_name
          [ journey_pattern.registration_number, journey_pattern.name ].join(" - ")
        end

        def geometry
          workgroup.route_planner.shape(waypoints)
        end

        def stop_area_ids
          @stop_area_ids ||=
            journey_pattern.stop_points.map{ |stop_point| stop_point.stop_area&.id }.join('-')
        end
      end

      def shape_cache
        @shape_cache ||= {}
      end

      def journey_patterns
        context.journey_patterns.without_associated_shape.includes(:stop_points)
      end

      def shapes
        workgroup.shape_referential.shapes
      end

      def shape_provider
        workbench.shape_providers.first
      end
    end
  end
end