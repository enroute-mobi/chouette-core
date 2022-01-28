module Macro
  class Context < ApplicationModel
    self.table_name = "macro_contexts"

    belongs_to :macro_list, class_name: "Macro::List", optional: false, inverse_of: :macro_contexts

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_context_id", inverse_of: :macro_context
    has_many :macro_context_runs, class_name: "Macro::Context::Run", foreign_key: "macro_context_id", inverse_of: :macro_context

    store :options, coder: JSON

    def build_run
      run_attributes = {
        name: name,
        options: options,
        comments: comments,
      }
      context_runs = run_class.new run_attributes
      macros.each do |macro|
        context_runs.macro_runs << macro.build_run
      end
      context_runs
    end

    def run_class
      @run_class ||= self.class.const_get("Run")
    end

    class Run < ApplicationModel
      self.table_name = "macro_context_runs"

      belongs_to :macro_list_run, class_name: "Macro::List::Run", optional: false, inverse_of: :macro_context_runs
      belongs_to :macro_context, class_name: "Macro::Context", optional: true, inverse_of: :macro_context_runs

      has_many :macro_runs, -> { order(position: :asc) }, class_name: "Macro::Base::Run", foreign_key: "macro_context_run_id", inverse_of: :macro_context_run

      store :options, coder: JSON

      delegate :referential, :workbench, to: :macro_list_run

      def context
        referential || WorkbenchScope.new(workbench)
      end

      def run
        logger.tagged "#{self.class.to_s}(id:#{id||object_id})" do
          macro_runs.each(&:run)
        end
      end
    end

    class WorkbenchScope
      def initialize(workbench)
        @workbench = workbench
      end

      def lines
        @workbench.lines
      end

      def routes
        Chouette::Route.none
      end

      def stop_points
        Chouette::StopPoint.none
      end

      def stop_areas
        @workbench.stop_areas
      end

      def journey_patterns
        Chouette::JourneyPattern.none
      end

      def vehicle_journeys
        Chouette::VehicleJourney.none
      end
    end
  end
end
