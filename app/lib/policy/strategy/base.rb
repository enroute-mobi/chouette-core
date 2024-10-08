# frozen_string_literal: true

module Policy
  module Strategy
    # Base class for Policy strategy implementations
    class Base
      class << self
        def context_class
          nil
        end
      end

      def initialize(policy)
        @policy = policy
      end
      attr_reader :policy

      delegate :resource, :context, to: :policy

      def apply?(_action, *_args)
        false
      end
    end
  end
end
