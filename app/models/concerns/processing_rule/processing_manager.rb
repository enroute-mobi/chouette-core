# frozen_string_literal: true

module ProcessingRule
  module ProcessingManager
    extend ActiveSupport::Concern

    class_methods do
      def processing_candidate_operation_steps
        raise NotImplementedError
      end
    end

    def create_processing(processing_rule, **options)
      self.class::ProcessingBuilder.new(processing_rule, **options).create
    end
  end
end
