# frozen_string_literal: true

module Policy
  module Strategy
    class LineProvider < Strategy::Provider
      protected

      def provider
        resource.line_provider
      end
    end
  end
end
