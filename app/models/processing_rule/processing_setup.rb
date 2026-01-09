# frozen_string_literal: true

module ProcessingRule
  class ProcessingSetup < ApplicationStoreModel
    include ::Processable

    validates :type, inclusion: { in: ->(r) { r.parent&.candidate_processing_setup_types || [] } }

    class << self
      def candidate_operation_steps
        []
      end
    end

    def build_processed(attributes)
      processed_klass.create!(processed_attributes(attributes))
    end

    protected

    def processed_klass
      raise NotImplementedError
    end

    def processed_attributes(attributes)
      attributes
    end
  end
end
