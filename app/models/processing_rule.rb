module ProcessingRule 
  class Base < ApplicationModel
    self.table_name = :processing_rules
    self.abstract_class = true
    
    extend Enumerize

    # Macro::List or Control::List to be started
    belongs_to :processable, polymorphic: true, required: true
    validates :operation_step, presence: true
  end

  class Workbench < Base
    belongs_to :workbench, required: true

    enumerize :processable_type, in: %w[Macro::List Control::List]
    enumerize :operation_step, in: %w(after_import before_merge after_merge), scope: :shallow

    validates :operation_step, inclusion: { in: %w(after_import before_merge) }, if: :use_macro_list?
    validates :operation_step, uniqueness: { scope: [:processable_type,:workbench] }

    def use_control_list?
      processable_type == Control::List.name
    end
    

    def control_list_id
      processable_id if use_control_list?
    end
    def control_list_id=(control_list_id)
      self.processable_id = control_list_id
    end

    def candidate_control_lists
      workbench.control_lists_shared_with_workgroup
    end

    validates :control_list_id, presence: true, if: :use_control_list?
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_control_lists } }, if: :use_control_list?

    def use_macro_list?
      processable_type == Macro::List.name
    end

    def macro_list_id
      processable_id if use_macro_list?
    end
    def macro_list_id=(macro_list_id)
      self.processable_id = macro_list_id
    end
    def candidate_macro_lists
      workbench.macro_lists
    end

    validates :macro_list_id, presence: true, if: :use_macro_list?
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_macro_lists } }, if: :use_macro_list?

    def self.policy_class
      ProcessingRuleWorkbenchPolicy
    end
  end

  class Workgroup < Base
    belongs_to :workgroup, required: true
    has_array_of :target_workbenches, class_name: 'Workbench'

    enumerize :processable_type, in: %w(Control::List)
    enumerize :operation_step, in: %w(after_import before_merge after_merge after_aggregate), scope: :shallow

    def self.policy_class
      ProcessingRuleWorgroupPolicy
    end
  end
end