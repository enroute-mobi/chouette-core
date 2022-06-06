class Macro::Context::TransportMode < Macro::Context
  option :transport_mode

  validates_presence_of :transport_mode

  class Run < Macro::Context::Run

    def scope(initial_scope = parent.scope)
      Scope.new(initial_scope, options[:transport_mode])
    end

    class Scope
      def initialize(initial_scope, transport_mode)
        @initial_scope = initial_scope
        @transport_mode = transport_mode
      end
      attr_accessor :initial_scope, :transport_mode

      def lines
        context.lines.where(transport_mode: transport_mode)
      end

      def routes
        context.routes.where(line: lines)
      end

      def stop_points
        context.stop_points.where(route: routes)
      end

      def stop_areas
        context.stop_areas.where(id: stop_points.select(:stop_area_id))
      end

      def journey_patterns
        context.journey_patterns.where(route: routes)
      end

      def vehicle_journeys
        context.vehicle_journeys.where(journey_pattern: journey_patterns)
      end
    end
  end
end
