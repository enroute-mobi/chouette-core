# frozen_string_literal: true

module Macro
  class Context
    class SavedSearch < Macro::Context
      option :saved_search_id

      validates :saved_search_id, presence: true

      def candidate_saved_searches
        [].tap do |groups|
          if (stop_area_saved_searches = saved_searches.for('Search::StopArea').presence)
            groups << [
              Chouette::StopArea.model_name.human.pluralize.capitalize,
              stop_area_saved_searches.sort_by(&:name).pluck(:name, :id)
            ]
          end

          if (line_saved_searches = saved_searches.for('Search::Line').presence)
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

      class Run < Macro::Context::Run
        def scope(initial_scope = parent.scope)
          Scope.new(initial_scope, saved_search)
        end

        delegate :saved_searches, to: :workbench

        def saved_search
          @saved_search ||= saved_searches.find_by(id: options[:saved_search_id])
        end

        class Scope
          def initialize(initial_scope, saved_search)
            @initial_scope = initial_scope
            @saved_search = saved_search
          end

          attr_reader :initial_scope, :saved_search

          def search
            @search ||= saved_search&.search
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
              search.without_pagination.search(initial_scope.lines)
            when :stop_areas
              initial_scope.lines.joins(:routes).where("routes.id IN (#{routes.select(:id).to_sql})").distinct
            else
              initial_scope.lines
            end
          end

          def routes
            if collection_name == :stop_areas
              initial_scope.routes.joins(:stop_points).where("stop_points.id IN (#{stop_points.select(:id).to_sql})").distinct
            else
              initial_scope.routes.where(line: lines)
            end
          end

          def stop_points
            if collection_name == :stop_areas
              return initial_scope.stop_points.where(stop_area_id: stop_areas.select(:id))
            end

            initial_scope.stop_points.where(route: routes)
          end

          def stop_areas
            return search.without_pagination.search(initial_scope.stop_areas) if collection_name == :stop_areas

            initial_scope.stop_areas.where(id: stop_points.select(:stop_area_id))
          end

          def companies
            initial_scope.companies.where(id: lines.where.not(company_id: nil).select(:company_id).distinct)
          end

          def networks
            initial_scope.networks.where(id: lines.where.not(network_id: nil).select(:network_id).distinct)
          end

          def entrances
            initial_scope.entrances.where(stop_area: stop_areas)
          end

          def journey_patterns
            initial_scope.journey_patterns.where(route: routes)
          end

          def vehicle_journeys
            initial_scope.vehicle_journeys.where(journey_pattern: journey_patterns)
          end

          def shapes
            initial_scope.shapes.where(id: journey_patterns.select(:shape_id))
          end

          def service_counts
            initial_scope.service_counts.where(line: lines)
          end

          def networks
            initial_scope.networks.where(id: lines.where.not(network_id: nil).select(:network_id))
          end

          def point_of_interests
            initial_scope.point_of_interests.where(shape_provider_id: shapes.select(:shape_provider_id))
          end

          delegate :documents, to: :initial_scope

          def connection_links
            initial_scope.connection_links.where(stop_area_provider_id: stop_areas.select(:stop_area_provider_id))
          end
        end
      end
    end
  end
end
