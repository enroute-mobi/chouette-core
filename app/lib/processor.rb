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
    referentials.compact.each do |referential|
      before_processing_rules.each do |processing_rule|
        return false unless processing_rule.perform operation: operation, referential: referential,
                                                    operation_workbench: workbench
      end
    end
    true
  end

  def after(referentials)
    # Specific case when operation is "Aggregate" and there is no workbench defined
    operation_workbench = workbench.blank? && workgroup.present? ? workgroup.owner_workbench : workbench

    referentials.compact.each do |referential|
      after_processing_rules.each do |processing_rule|
        return false unless processing_rule.perform operation: operation, referential: referential,
                                                    operation_workbench: operation_workbench
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

  # Retrieve all processing rules for a workgroup
  def all_workgroup_processing_rules(operation_step)
    workgroup.processing_rules.where(operation_step: operation_step)
  end

  # Retrieve processing rules for a workgroup and filter by workbench if needed
  def workgroup_processing_rules(operation_step)
    processing_rules = all_workgroup_processing_rules(operation_step)
    return processing_rules if workbench.blank?

    processing_rules.where(
      'target_workbench_ids && ARRAY[?]::bigint[] OR ARRAY_LENGTH(target_workbench_ids, 1) IS NULL', workbench
    )
  end

  def before_operation_step
    "before_#{operation.model_name.singular}"
  end

  def after_operation_step
    "after_#{operation.model_name.singular}"
  end
end
