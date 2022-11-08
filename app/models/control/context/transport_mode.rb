class Control::Context::TransportMode < Control::Context
  option :transport_mode

  validates_presence_of :transport_mode

  class Run < Control::Context::Run
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
      context.vehicle_journeys.where(journey_pattern: journey_patterns)
    end

    def service_counts
      context.service_counts.where(line: lines)
    end
  end
end
