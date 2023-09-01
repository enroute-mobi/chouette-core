class Control::Context::SavedSearch < Control::Context
  module Options
    extend ActiveSupport::Concern

    included do
      option :saved_search_id
      option :target_model

      enumerize :target_model, in: %w[Line StopArea]
      validates_presence_of :saved_search_id

      def candidate_saved_searches
        saved_searches
      end

      def saved_searches
        klass = "::Search::#{target_model}".constantize
        workbench.saved_searches.for(klass)
      end
    end
  end
  include Options

  class Run < Control::Context::Run
    include Options

    %i[stop_areas lines].each do |method|
      define_method method do
        if saved_search = saved_searches.find_by(id: saved_search_id)
          saved_search.search(context.send(method)).collection
        end
      end
    end
  end
end
