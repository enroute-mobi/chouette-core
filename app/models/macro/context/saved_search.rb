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
            return search.without_pagination.search(initial_scope.lines) if collection_name == :lines

            initial_scope.lines.joins(:routes).where(routes: routes).distinct
          end

          def routes
            case collection_name
            when :lines
              initial_scope.routes.where(line: lines)
            when :stop_areas
              initial_scope.routes.joins(:stop_points).where(stop_points: stop_points).distinct
            else
              initial_scope.routes
            end
          end

          def stop_points
            if collection_name == :stop_areas
              return initial_scope.stop_points.where(stop_area: stop_areas)
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

          def connection_links
            initial_scope.connection_links.where(
              departure_id: stop_areas.select(:id),
              arrival_id: stop_areas.select(:id)
            )
          end

          def shapes
            initial_scope.shapes.where(id: journey_patterns.select(:shape_id))
          end

          def documents
            workgroup.documents.where(
              id: line_document_memberships.or(stop_area_document_memberships)
                                          .or(company_document_memberships)
                                          .select(:document_id)
                                          .distinct
            )
          end

          def journey_patterns
            initial_scope.journey_patterns.where(route: routes)
          end

          def vehicle_journeys
            initial_scope.vehicle_journeys.where(journey_pattern: journey_patterns)
          end

          def time_tables
            initial_scope.time_tables.joins(:vehicle_journeys).where(
              vehicle_journeys: { id: vehicle_journeys.select(:id) }
            )
          end

          def service_counts
            initial_scope.service_counts.where(line: lines)
          end

          delegate :workgroup, :point_of_interests, to: :initial_scope

          private

          def line_document_memberships
            workgroup.document_memberships.where(
              documentable_type: 'Chouette::Line',
              documentable_id: lines.select(:id)
            )
          end

          def stop_area_document_memberships
            workgroup.document_memberships.where(
              documentable_type: 'Chouette::StopArea',
              documentable_id: stop_areas.select(:id)
            )
          end

          def company_document_memberships
            workgroup.document_memberships.where(
              documentable_type: 'Chouette::Company',
              documentable_id: companies.select(:id)
            )
          end
        end
      end
    end
  end
end
