# frozen_string_literal: true

module Policy
  module Strategy
    class Provider < Strategy::Workbench
      protected

      def workbench
        provider&.workbench
      end

      def provider
        raise NotImplementedError
      end
    end
  end
end
