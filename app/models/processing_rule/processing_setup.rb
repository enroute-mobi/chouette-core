# frozen_string_literal: true

module ProcessingRule
  class ProcessingSetup < ApplicationStoreModel
    include ProcessingManager

    validates :type, inclusion: { in: ->(r) { r.parent&.candidate_processing_setup_types || [] } }

    class << self
      def candidate_operation_steps
        []
      end
    end

    def processed_klass
      raise NotImplementedError
    end

    class ProcessingBuilder < ::ProcessingRule::ProcessingBuilder
      delegate :processing_setup, to: :processing_rule

      protected

      def build_processed
        processing_setup.processed_klass.create!(
          workbench: operation_workbench,
          processing_rule: processing_rule,
          operation: operation,
          creator: 'Webservice'
        )
      end
    end
  end
end
