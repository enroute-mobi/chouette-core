# frozen_string_literal: true

module Policy
  module Strategy
    class Referential < Strategy::Workbench
      class << self
        def context_class
          ::Policy::Context::Referential
        end
      end

      def apply(_action, *_args)
        !context.referential_read_only? && super
      end

      protected

      def workbench
        context.referential.workbench
      end
    end
  end
end
