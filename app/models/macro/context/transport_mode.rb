class Macro::Context::TransportMode < Macro::Context
  class Run < Macro::Context::Run
    def lines
      context.lines.where(transport_mode: options[:transport_mode])
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
      context.vehcile_journeys.where(journey_pattern: journey_patterns)
    end
  end
end