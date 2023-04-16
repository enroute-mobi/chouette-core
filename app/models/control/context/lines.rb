class Control::Context::Lines < Control::Context
  module Options
    extend ActiveSupport::Concern

    included do
      option :line_ids

      validate :workbench_lines_contain_selected_lines

      def line_collection
        selected_lines.map{ |l| {id: l.id, text: "#{l.name} - #{l.registration_number}"} }
      rescue
        []
      end

      def selected_line_ids
        return line_ids if line_ids.is_a? Array

        line_ids.to_s.split(',')
      end

      private

      def workbench_lines_contain_selected_lines
        unless selected_lines.count == selected_line_ids.count
          errors.add(:line_ids, :invalid)
        end
      end

      def selected_lines
        workbench.lines.distinct.where(id: selected_line_ids)
      end

    end
  end
  include Options

  class Run < Control::Context::Run

    include Options

    def lines
      context.lines.where(id: selected_line_ids)
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
