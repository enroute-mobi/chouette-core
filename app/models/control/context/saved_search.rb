class Control::Context::SavedSearch < Control::Context
  option :saved_search

  validates_presence_of :saved_search

  class Run < Control::Context::Run
    option :saved_search

    %i[stop_areas lines].each do |method|
      define_method method do
        
        if saved_search = saved_searches(__method__).find_by(id: saved_search)
          saved_search.search(scope, {})
        end
      end
    end

    def saved_searches(klass)
      workbench.saved_searches.for("::Search::#{klass.to_s.classify}".constantize)
    end
  end
end
