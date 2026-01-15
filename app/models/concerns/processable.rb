# frozen_string_literal: true

module Processable
  extend ActiveSupport::Concern

  class_methods do
    def processing_candidate_operation_steps
      raise NotImplementedError
    end
  end

  def create_processing(processing_rule, **options)
    ProcessingBuilder.new(self, processing_rule, **options).create
  end

  def build_processed(attributes)
    raise NotImplementedError
  end

  class ProcessingBuilder
    def initialize(processable, processing_rule, operation: nil, referential: nil, operation_workbench: nil)
      @processable = processable
      @processing_rule = processing_rule
      @operation = operation
      @referential = referential
      @operation_workbench = operation_workbench
    end
    attr_reader :processable, :processing_rule, :operation, :referential, :operation_workbench

    def create
      processed = processable.build_processed(processed_attributes)

      processing_rule.processings.create(
        step: processing_step,
        operation: operation,
        workbench: operation_workbench,
        workgroup_id: processing_rule.workgroup_id,
        processed: processed
      )
    end

    private

    def processed_attributes
      {
        workbench: operation_workbench,
        referential: referential,
        processing_rule: processing_rule,
        operation: operation,
        creator: 'Webservice'
      }
    end

    def processing_step
      processing_rule.operation_step.split('_').first if processing_rule.operation_step.present?
    end
  end
end
