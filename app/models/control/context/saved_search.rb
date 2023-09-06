class Control::Context::SavedSearch < Control::Context
  module Options
    extend ActiveSupport::Concern

    included do
      option :saved_search_id

      validates_presence_of :saved_search_id

      def candidate_saved_searches
        [].tap do |groups|
          if stop_area_saved_searches = saved_searches.for('Search::StopArea').presence
            groups << [
              Chouette::StopArea.model_name.human.pluralize.capitalize,
              stop_area_saved_searches.sort_by(&:name).pluck(:name, :id)
            ]
          end

          if line_saved_searches = saved_searches.for('Search::Line').presence
            groups << [
              Chouette::Line.model_name.human.pluralize.capitalize,
              line_saved_searches.sort_by(&:name).pluck(:name, :id)
            ]
          end
        end
      end

      def saved_searches
        @saved_searches ||= workbench.saved_searches
      end
    end
  end
  include Options

  class Run < Control::Context::Run
    include Options

    def saved_search
      @saved_search ||= saved_searches.find_by(id: saved_search_id)
    end

    def search_type
      @search_type ||= saved_search.search_type
    end

    def collection_name
      search_type.demodulize.underscore.pluralize.to_sym
    end

    def lines
      case collection_name
      when :lines
        saved_search.search(context.lines).without_pagination.collection
      when :stop_areas
        context.lines.where(routes: routes.select(:id)).distinct
      else
        context.lines
      end
    end

    def routes
      return context.routes.where(stop_points: stop_points.select(:id)).distinct if collection_name == :stop_areas

      context.routes.where(line: lines)
    end

    def stop_points
      return context.stop_points.where(stop_area_id: stop_areas.select(:id)) if collection_name == :stop_areas

      context.stop_points.where(route: routes)
    end

    def stop_areas
      return saved_search.search(context.stop_areas).without_pagination.collection if collection_name == :stop_areas

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
