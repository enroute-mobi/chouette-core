class Control::Context::OperatingPeriod < Control::Context
  option :next_days

  validates_presence_of :next_days

  class Run < Control::Context::Run

    def vehicle_journeys
      context.vehicle_journeys.with_matching_timetable data_range
    end

    def lines
      context.lines.distinct.joins(:vehicle_journeys)
        .where(vehicle_journeys: { id: vehicle_journeys })
    end

    def routes
      context.routes.distinct.joins(:vehicle_journeys)
        .where(vehicle_journeys: { id: vehicle_journeys })
    end

    def stop_points
      context.stop_points.distinct.joins(route: :vehicle_journeys)
        .where(vehicle_journeys: { id: vehicle_journeys })
    end

    def stop_areas
      stop_areas_in_routes =
        context.stop_areas.joins(routes: :vehicle_journeys).distinct
          .where(vehicle_journeys: { id: vehicle_journeys })

      stop_areas_in_specific_vehicle_journey_at_stops =
        context.stop_areas.joins(:specific_vehicle_journey_at_stops).distinct
          .where(vehicle_journey_at_stops: { vehicle_journey_id: vehicle_journeys })

      context.stop_areas.union(stop_areas_in_routes, stop_areas_in_specific_vehicle_journey_at_stops)
    end

    def journey_patterns
      context.journey_patterns.distinct.joins(:vehicle_journeys)
        .where(vehicle_journeys: { id: vehicle_journeys })
    end

    def companies
      context.companies.where(id: lines.where.not(company_id: nil).select(:company_id))
    end

    def networks
      context.networks.where(id: lines.where.not(network_id: nil).select(:network_id))
    end

    def time_tables
      context.time_tables.joins(:vehicle_journeys)
        .where(vehicle_journeys: { id: vehicle_journeys })
    end

    def vehicle_journey_at_stops
      context.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)
    end

    def shapes
      context.shapes.where(id: journey_patterns.select(:shape_id))
    end

    def entrances
      context.entrances.where(stop_area: stop_areas)
    end

    def routing_constraint_zones
      context.routing_constraint_zones.where(route: routes)
    end

    def data_range
      date = Date.current
      date..(date + options[:next_days])
    end
  end
end