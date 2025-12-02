# frozen_string_literal: true

module ProcessingRule
  class ProcessingBuilder
    def initialize(processing_rule, operation: nil, referential: nil, operation_workbench: nil)
      @processing_rule = processing_rule
      @operation = operation
      @referential = referential
      @operation_workbench = operation_workbench
    end
    attr_reader :processing_rule, :operation, :referential, :operation_workbench

    def create
      processed = build_processed

      processing_rule.processings.create(
        step: processing_step,
        operation: operation,
        workbench: operation_workbench,
        workgroup_id: processing_rule.workgroup_id,
        processed: processed
      )
    end

    protected

    def build_processed
      nil
    end

    private

    def processing_step
      processing_rule.operation_step.split('_').first if processing_rule.operation_step.present?
    end
  end
end
