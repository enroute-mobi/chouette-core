module Macro
  class CreateShape < Macro::Base
    class Run < Macro::Base::Run
      def run
        journey_patterns.find_in_batches(batch_size: 100) do |group|
          batch = workgroup.route_planner.batch

          factories_by_ids = {}

          group.each do |journey_pattern|
            factory = ShapeFactory.new(journey_pattern, shape_provider)
            # Incomplete geometry
            next unless factory.waypoints

            # A shape has been already computed for this sequence
            if (shape_id = shape_cache[factory.stop_area_ids])
              journey_pattern.update shape_id: shape_id
            else
              batch.shape factory.waypoints, key: journey_pattern.id
              # Keep the factory in memory
              factories_by_ids[journey_pattern.id] = factory
            end
          end

          batch.shapes.each do |key, geometry|
            factory = factories_by_ids[key]
            factory.geometry = geometry

            shape = factory.shape
            next unless shape

            shape_cache[factory.stop_area_ids] = shape.id
            journey_pattern = factory.journey_pattern
            journey_pattern.update shape: shape
            create_message(journey_pattern)
          end
        end
      end

      # Create a message for the given JourneyPattern
      # If the JourneyPattern is invalid, an error message is created.
      def create_message(journey_pattern)
        attributes = {
          criticity: 'info',
          message_attributes: { shape_name: shape.uuid, journey_pattern_name: journey_pattern.name },
          source: journey_pattern
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless journey_pattern.valid?

        macro_messages.create!(attributes)
      end

      class ShapeFactory
        def initialize(journey_pattern, shape_provider)
          @journey_pattern = journey_pattern
          @shape_provider = shape_provider
        end
        attr_accessor :journey_pattern, :geometry, :shape_provider

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
