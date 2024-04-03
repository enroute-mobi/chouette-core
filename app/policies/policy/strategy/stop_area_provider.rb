# frozen_string_literal: true

module Policy
  module Strategy
    class StopAreaProvider < Strategy::Provider
      protected

      def provider
        resource.stop_area_provider
      end
    end
  end
end
