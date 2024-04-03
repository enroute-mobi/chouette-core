# frozen_string_literal: true

module Policy
  module Strategy
    class Workbench < Strategy::Base
      class << self
        def context_class
          ::Policy::Context::HasWorkbench
        end
      end

      def apply(_action, *_args)
        context.workbench?(workbench)
      end

      protected

      def workbench
        resource.workbench
      end
    end
  end
end
