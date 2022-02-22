module Macro
  class CreateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_each do |journey_pattern|
          waypoints = journey_pattern.waypoints

          shape = shape_provider.shapes.create(
            name: shape_name(journey_pattern),
            waypoints: waypoints,
            geometry: workgroup.route_planner.shape(waypoints)
          )

          journey_pattern.update shape: shape if shape.present?
        end
      end

      def journey_patterns
        context.journey_patterns.without_associated_shape.includes(:shape, stop_points: :stop_area)
      end

      def shape_name(journey_pattern)
        [ journey_pattern.line.name, journey_pattern.registration_number, journey_pattern.name ].join(" - ")
      end

      def shapes
        workgroup.shape_referential.shapes
      end

      def shape_provider
        workgroup.shape_referential.shape_providers.first
      end
    end
  end
end