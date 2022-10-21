# frozen_string_literal: true

module ProcessingRule
  # Base model to define Workbench and Workgroup ProcessingRule
  class Base < ApplicationModel
    self.table_name = :processing_rules

    extend Enumerize

    # Macro::List or Control::List to be started
    belongs_to :processing, polymorphic: true, required: true
    validates :operation_step, presence: true

    def use_control_list?
      processing_type == Control::List.name
    end

    def control_list_id
      processing_id if use_control_list?
    end

    def control_list_id=(control_list_id)
      self.processing_id = control_list_id
    end

    validates :control_list_id, presence: true, if: :use_control_list?
    validates :processing, inclusion: { in: ->(rule) { rule.candidate_control_lists } }, if: :use_control_list?
  end

  # Workbench ProcessingRule managed as Workbench#processing_rules
  class Workbench < Base
    belongs_to :workbench, required: true

    enumerize :processing_type, in: %w[Macro::List Control::List]
    enumerize :operation_step, in: %w[after_import before_merge after_merge], scope: :shallow

    validates :operation_step, inclusion: { in: %w[after_import before_merge] }, if: :use_macro_list?
    validates :operation_step, uniqueness: { scope: %i[processing_type workbench] }

    def use_macro_list?
      processing_type == Macro::List.name
    end

    def macro_list_id
      processing_id if use_macro_list?
    end

    def macro_list_id=(macro_list_id)
      self.processing_id = macro_list_id
    end

    def candidate_macro_lists
      workbench&.macro_lists || Macro::List.none
    end

    validates :macro_list_id, presence: true, if: :use_macro_list?
    validates :processing, inclusion: { in: ->(rule) { rule.candidate_macro_lists } }, if: :use_macro_list?

    def candidate_control_lists
      workbench&.control_lists_shared_with_workgroup || Control::List.none
    end

    def self.policy_class
      ProcessingRuleWorkbenchPolicy
    end
  end

  # Workgroup ProcessingRule managed as Workgroup#processing_rules
  class Workgroup < Base
    belongs_to :workgroup, required: true
    has_array_of :target_workbenches, class_name: 'Workbench'

    enumerize :processing_type, in: %w[Control::List]
    enumerize :operation_step, in: %w[after_import before_merge after_merge after_aggregate], scope: :shallow

    def self.policy_class
      ProcessingRuleWorkgroupPolicy
    end

    def candidate_control_lists
      workgroup ? workgroup.control_lists.shared : Control::List.none
    end

    def candidate_target_workbenches
      workgroup.workbenches
    end

    validates :operation_step, uniqueness: { scope: %i[processing_type workgroup] }
    validates :control_list_id, presence: true
  end
end
