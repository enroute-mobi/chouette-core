class Control::Context::Lines < Control::Context
  option :line_ids

  validates_presence_of :line_ids

  class Run < Control::Context::Run

    def lines
      context.lines.where(id: options[:line_ids])
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

    def candidate_lines
      context.lines
    end
  end
end
