# frozen_string_literal: true

module ProcessingRule
  # Base model to define Workbench and Workgroup ProcessingRule
  class Base < ApplicationModel
    self.table_name = :processing_rules

    extend Enumerize

    # Macro::List or Control::List to be started
    belongs_to :processable, polymorphic: true # CHOUETTE-3247 required: true
    has_many :processings, foreign_key: 'processing_rule_id'

    validates :operation_step, presence: true
    validates :control_list_id, presence: true, if: :use_control_list?
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_control_lists } }, if: :use_control_list?

    def use_control_list?
      processable_type == Control::List.name
    end

    def control_list_id
      processable_id if use_control_list?
    end

    def control_list_id=(control_list_id)
      self.processable_id = control_list_id
    end

    def perform(operation: nil, referential: nil, operation_workbench: nil)
      if use_control_list?
        processed = processable.control_list_runs.new(name: processable.name,
                                                      creator: 'Webservice',
                                                      referential: referential,
                                                      workbench: operation_workbench)
        processed.build_with_original_control_list
      else
        processed = processable.macro_list_runs.new(name: processable.name,
                                                    creator: 'Webservice',
                                                    referential: referential,
                                                    workbench: operation_workbench)
        processed.build_with_original_macro_list
      end

      processing = processings.create step: processing_step,
                                      operation: operation,
                                      workbench: operation_workbench,
                                      workgroup_id: workgroup_id,
                                      processed: processed
    
      processing.perform
    end

    def processing_step
      operation_step.split('_').first if operation_step.present?
    end 
  end

  # Workbench ProcessingRule managed as Workbench#processing_rules
  class Workbench < Base
    belongs_to :workbench # CHOUETTE-3247 required: true

    enumerize :processable_type, in: %w[Macro::List Control::List]
    enumerize :operation_step, in: %w[after_import before_merge after_merge], scope: :shallow

    validates :operation_step, inclusion: { in: %w[after_import before_merge] }, if: :use_macro_list?
    validates :operation_step, uniqueness: { scope: %i[processable_type workbench] }

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
      workbench&.macro_lists || Macro::List.none
    end

    validates :macro_list_id, presence: true, if: :use_macro_list?
    validates :processable, inclusion: { in: ->(rule) { rule.candidate_macro_lists } }, if: :use_macro_list?

    def candidate_control_lists
      workbench&.control_lists_shared_with_workgroup || Control::List.none
    end
  end

  # Workgroup ProcessingRule managed as Workgroup#processing_rules
  class Workgroup < Base
    belongs_to :workgroup # CHOUETTE-3247 required: true
    has_array_of :target_workbenches, class_name: 'Workbench'

    enumerize :processable_type, in: %w[Control::List]
    enumerize :operation_step, in: %w[after_import before_merge after_merge after_aggregate], scope: :shallow

    def candidate_control_lists
      workgroup ? workgroup.control_lists.shared : Control::List.none
    end

    def candidate_target_workbenches
      workgroup.workbenches
    end

    validates :operation_step, uniqueness: { scope: %i[processable_type workgroup] }
    validates :control_list_id, presence: true
  end
end
