# frozen_string_literal: true

module Control
  class Context
    class SavedSearch < Control::Context
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

      class Run < Control::Context::Run
        def scope
          saved_search.search.scope(context)
        end

        delegate :saved_searches, to: :workbench
        delegate :lines,
                 :line_groups,
                 :line_notices,
                 :companies,
                 :networks,
                 :stop_areas,
                 :stop_area_groups,
                 :entrances,
                 :connection_links,
                 :shapes,
                 :point_of_interests,
                 :service_facility_sets,
                 :accessibility_assessments,
                 :fare_zones,
                 :line_routing_constraint_zones,
                 :document_memberships,
                 :documents,
                 :contracts,
                 :routes,
                 :stop_points,
                 :journey_patterns,
                 :journey_pattern_stop_points,
                 :vehicle_journeys,
                 :vehicle_journey_at_stops,
                 :time_tables,
                 :time_table_periods,
                 :time_table_dates,
                 :service_counts,
                 to: :scope

        def saved_search
          @saved_search ||= saved_searches.find_by(id: options[:saved_search_id])
        end
      end
    end
  end
end
