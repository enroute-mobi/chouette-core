# frozen_string_literal: true

class Processor
  attr_reader :operation, :workbench

  def initialize(operation)
    @operation = operation
    @workbench = operation.try(:workbench)
  end

  delegate :parent, to: :operation, allow_nil: true

  def workgroup
    @workgroup ||= workbench.present? ? workbench.workgroup : operation.try(:workgroup)
  end

  # Specific case when operation is "Aggregate" and there is no workbench defined
  def operation_workbench
    @operation_workbench ||= workbench.blank? && workgroup.present? ? workgroup.owner_workbench : workbench
  end

  def before
    perform_processing_rules(before_processing_rules, before_referentials)
  end

  def after
    perform_processing_rules(after_processing_rules, after_referentials)
  end

  def around
    failure = before
    return failure unless failure

    yield

    after
  end

  def before_processing_rules
    # Returns Processing Rules associated to an operation with a specific order:
    #   Macro List first
    #   Control List
    #   Workgroup Control List
    @before_processing_rules ||= workbench_processing_rules(before_operation_step) + \
                                 workgroup_processing_rules(before_operation_step)
  end

  def after_processing_rules
    # Returns Processing Rules associated to an operation with a specific order:
    #   Macro List first
    #   Control List
    #   Workgroup Control List
    @after_processing_rules ||= workbench_processing_rules(after_operation_step) + \
                                workgroup_processing_rules(after_operation_step)
  end

  def workbench_processing_rules(operation_step)
    return [] unless workbench.present?

    workbench.processing_rules.compatible_with_operation_via_tags(operation_step, tag_ids)
  end

  # Retrieve all processing rules for a workgroup
  def all_workgroup_processing_rules(operation_step)
    workgroup.processing_rules.where(operation_step: operation_step)
  end

  # Retrieve processing rules for a workgroup and filter by workbench if needed
  def workgroup_processing_rules(operation_step)
    processing_rules = all_workgroup_processing_rules(operation_step)
    return processing_rules if workbench.blank?

    processing_rules.accept_workbench(workbench)
  end

  def before_operation_step
    "before_#{operation.model_name.singular}"
  end

  def after_operation_step
    "after_#{operation.model_name.singular}"
  end

  protected

  # XXX_referentials: nil to perform processing rules without referential, [] to not perform processing rules

  def before_referentials
    nil
  end

  def after_referentials
    nil
  end

  private

  def tag_ids
    @tag_ids ||= parent.try(:tags).try(:pluck, :id) || []
  end

  def perform_processing_rules(processing_rules, referentials)
    return true unless processing_rules.any?

    if referentials
      referentials.all? do |referential|
        processing_rules.all? do |processing_rule|
          processing_rule.perform(referential: referential, **perform_arguments)
        end
      end
    else
      processing_rules.all? do |processing_rule|
        processing_rule.perform(**perform_arguments)
      end
    end
  end

  def perform_arguments
    { operation: operation, operation_workbench: operation_workbench }
  end
end
