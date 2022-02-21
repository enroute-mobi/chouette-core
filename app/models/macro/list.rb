module Macro
  class List < ApplicationModel
    self.table_name = "macro_lists"

    belongs_to :workbench, optional: false
    validates :name, presence: true

    has_many :macros, -> { order(position: :asc) }, class_name: "Macro::Base", dependent: :delete_all, foreign_key: "macro_list_id", inverse_of: :macro_list
    has_many :macro_list_runs, class_name: "Macro::List::Run", foreign_key: :original_macro_list_id
    has_many :macro_contexts, class_name: "Macro::Context", foreign_key: "macro_list_id", inverse_of: :macro_list

    accepts_nested_attributes_for :macros, allow_destroy: true, reject_if: :all_blank

    scope :by_text, ->(text) { text.blank? ? all : where('lower(name) LIKE :t', t: "%#{text.downcase}%") } 

    def self.policy_class
      MacroListPolicy
    end

    # macro_list_run = macro_list.build_run user: user, workbench: workbench, referential: target
    #
    # if macro_list_run.save
    #   macro_list_run.enqueue
    # else
    #   render ...
    # end

    class Run < Operation
      # The Workbench where macros are executed
      self.table_name = "macro_list_runs"

      belongs_to :workbench, optional: false
      delegate :workgroup, to: :workbench

      # The Referential where macros are executed.
      # Optional, because the user can run macros on Stop Areas for example
      belongs_to :referential, optional: true

      # The original macro list definition. This macro list can have been modified or deleted since.
      # Should only used to provide a link in the UI
      belongs_to :original_macro_list, optional: true, foreign_key: :original_macro_list_id, class_name: 'Macro::List'

      has_many :macro_runs, -> { order(position: :asc) }, class_name: "Macro::Base::Run",
               dependent: :delete_all, foreign_key: "macro_list_run_id"

      has_many :macro_context_runs, class_name: "Macro::Context::Run", dependent: :delete_all, foreign_key: "macro_list_run_id", inverse_of: :macro_list_run

      validates :name, presence: true
      validates :original_macro_list_id, presence: true, if: :new_record?

      def build_with_original_macro_list
        return unless original_macro_list

        original_macro_list.macros.each do |macro|
          macro_runs << macro.build_run
        end

        original_macro_list.macro_contexts.each do |macro_context|
          self.macro_context_runs << macro_context.build_run
        end

        self.workbench = original_macro_list.workbench
      end

      def self.policy_class
        MacroListRunPolicy
      end

      def perform
        referential.switch if referential

        macro_runs.each(&:run)
        macro_context_runs.each(&:run)
      end

    end
  end
end