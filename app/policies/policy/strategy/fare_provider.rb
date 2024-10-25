# frozen_string_literal: true

module Policy
  module Strategy
    class FareProvider < Strategy::Provider
      protected

      def provider
        resource.fare_provider
      end
    end
  end
end
