class Macro::Context::TransportMode < Macro::Context
  option :transport_mode

  validates_presence_of :transport_mode

  def candidate_transport_modes
    workbench.workgroup.sorted_transport_modes
  end

  class Run < Macro::Context::Run
    def transport_mode
      Chouette::TransportMode.new(options[:transport_mode])
    end

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
        initial_scope.lines.where(transport_mode: transport_mode)
      end

      def routes
        initial_scope.routes.where(line: lines)
      end

      def stop_points
        initial_scope.stop_points.where(route: routes)
      end

      def stop_areas
        initial_scope.stop_areas.where(id: stop_points.select(:stop_area_id))
      end

      def journey_patterns
        initial_scope.journey_patterns.where(route: routes)
      end

      def vehicle_journeys
        initial_scope.vehicle_journeys.where(journey_pattern: journey_patterns)
      end
    end
  end
end
