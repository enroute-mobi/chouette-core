class Processor
  attr_reader :operation, :workbench

  def initialize(operation)
    @operation = operation
    @workbench = operation.try(:workbench)
  end

  def workgroup
    @workgroup ||= workbench.present? ? workbench.workgroup : operation.try(:workgroup)
  end

  def before(referentials)
    referentials.each do |referential|
      before_processing_rules.each do |processing_rule|
        return false unless processing_rule.perform operation: operation, referential: referential,
                                                    operation_workbench: workbench
      end
    end
    true
  end

  def after(referentials)
    referentials.each do |referential|
      after_processing_rules.each do |processing_rule|
        return false unless processing_rule.perform operation: operation, referential: referential,
                                                    operation_workbench: workbench
      end
    end
    true
  end

  def before_processing_rules
    # Returns Processing Rules associated to an operation with a specific order:
    #   Macro List first
    #   Control List
    #   Workgroup Control List
    workbench_processing_rules(before_operation_step) + workgroup_processing_rules(before_operation_step)
  end

  def after_processing_rules
    # Returns Processing Rules associated to an operation with a specific order:
    #   Macro List first
    #   Control List
    #   Workgroup Control List
    workbench_processing_rules(after_operation_step) + workgroup_processing_rules(after_operation_step)
  end

  def workbench_processing_rules(operation_step)
    return [] unless workbench.present?

    workbench.processing_rules.where(operation_step: operation_step).order(processable_type: :desc)
  end

  def workgroup_processing_rules(operation_step)
    # Specific case when operation step is "after_aggregate" and operation is "Aggregate"
    return workgroup.processing_rules.where(operation_step: operation_step) if workbench.blank?

    dedicated_processing_rules = workgroup.processing_rules.where(operation_step: operation_step).with_target_workbenches_containing(workbench.id)

    return dedicated_processing_rules if dedicated_processing_rules.present?

    workgroup.processing_rules.where(operation_step: operation_step, target_workbench_ids: [])
  end

  def before_operation_step
    "before_#{operation.model_name.singular}"
  end

  def after_operation_step
    "after_#{operation.model_name.singular}"
  end
end
