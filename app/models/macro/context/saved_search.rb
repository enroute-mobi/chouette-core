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
          saved_search.search.scope(initial_scope)
        end

        delegate :saved_searches, to: :workbench

        def saved_search
          @saved_search ||= saved_searches.find_by(id: options[:saved_search_id])
        end
      end
    end
  end
end
