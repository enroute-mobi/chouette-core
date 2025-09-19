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

  def before(referentials)
    return true unless before_processing_rules.any?

    referentials.each do |referential|
      before_processing_rules.each do |processing_rule|
        return false unless processing_rule.perform operation: operation, referential: referential,
                                                    operation_workbench: workbench
      end
    end

    true
  end

  def after(referentials) # rubocop:disable Metrics/MethodLength
    return true unless after_processing_rules.any?

    unless operation_workbench
      Rails.logger.warn('Could not find a workbench to run after processings')
      return false
    end

    referentials.each do |referential|
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

    workbench
      .processing_rules
      .where(operation_step: operation_step)
      .where("(required_tag_ids && ARRAY[?]::int[]) OR ARRAY_LENGTH(required_tag_ids, 1) IS NULL", tag_ids)
      .where.not("(excluded_tag_ids && ARRAY[?]::int[]) AND ARRAY_LENGTH(excluded_tag_ids, 1) IS NOT NULL", tag_ids)
      .order(processable_type: :desc)
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

  private

  def tag_ids
    @tag_ids ||= parent.try(:tags).try(:pluck, :id) || []
  end
end
