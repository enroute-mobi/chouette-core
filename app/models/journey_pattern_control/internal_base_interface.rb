module JourneyPatternControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      def self.collection_type(_)
        :journey_patterns
      end
    end
  end
end
