class Control::Context::TransportMode < Control::Context
  option :transport_mode

  validates_presence_of :transport_mode

  def candidate_transport_modes
    workbench.workgroup.sorted_transport_modes
  end

  class Run < Control::Context::Run
    def lines
      context.lines.where(transport_mode: options[:transport_mode])
    end

    def companies
      context.companies.where(id: lines.select(:company_id).distinct)
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

    def entrances
      context.entrances.where(stop_area: stop_areas)
    end

    def journey_patterns
      context.journey_patterns.where(route: routes)
    end

    def vehicle_journeys
      context.vehicle_journeys.where(journey_pattern: journey_patterns)
    end

    def shapes
      context.shapes.where(id: journey_patterns.select(:shape_id))
    end

    def service_counts
      context.service_counts.where(line: lines)
    end

    def networks
      context.networks.where(id: lines.where.not(network_id: nil).select(:network_id))
    end

    def documents
      context.documents
    end

    def point_of_interests
      context.point_of_interests.joins(shape_provider: :shapes).where('shapes.id': shapes).distinct
    end

    def connection_links
      context.connection_links.where(stop_area_provider_id: stop_areas.select(:stop_area_provider_id))
    end
  end
end
