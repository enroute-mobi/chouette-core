class Control::Context::Lines < Control::Context
  module Options
    extend ActiveSupport::Concern

    included do
      option :line_ids
      validates :line_ids, presence: true, array_inclusion: { in: ->(context) { context.candidate_lines_id } }

      # Avoid empty string sends by select
      #  control_list[control_contexts_attributes][1690296924144][line_ids][]	[…]
      # 0	""
      # 1	"812"
      def line_ids=(lines)
        super(lines.reject(&:blank?).map(&:to_i))
      end

      def selected_lines
        workbench.lines.where(id: line_ids).order(:name)
      end

      def candidate_lines_id
        workbench.lines.pluck(:id)
      end

    end
  end
  include Options

  class Run < Control::Context::Run

    include Options

    def lines
      context.lines.where(id: selected_lines)
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

    def vehicle_journey_at_stops
      context.vehicle_journey_at_stops.where(vehicle_journey: vehicle_journeys)
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

    def point_of_interests
      context.point_of_interests.where(shape_provider_id: shapes.select(:shape_provider_id))
    end

    def documents
      context.documents
    end

    def connection_links
      context.connection_links.where(stop_area_provider_id: stop_areas.select(:stop_area_provider_id))
    end
  end
end
