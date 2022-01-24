module Macro
  class Context < ApplicationModel
    self.table_name = "macro_contexts"

    belongs_to :macro_list, class_name: "Macro::List", optional: false, inverse_of: :macro_contexts

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_context_id", inverse_of: :macro_context
    has_many :macro_context_runs, class_name: "Macro::Context::Run", foreign_key: "macro_context_id", inverse_of: :macro_context

    store :options, coder: JSON

    class Run < ApplicationModel
      self.table_name = "macro_context_runs"

      belongs_to :macro_list_run, class_name: "Macro::List::Run", optional: false, inverse_of: :macro_context_runs
      belongs_to :macro_context, class_name: "Macro::Context", optional: false, inverse_of: :macro_context_runs

      has_many :macro_runs, -> { order(position: :asc) }, class_name: "Macro::Base::Run", foreign_key: "macro_run_id", inverse_of: :macro_context_run

      store :options, coder: JSON

      delegate :referential, :workbench, to: :macro_list_run

      def context
        referential || workbench
      end
    end
  end
end