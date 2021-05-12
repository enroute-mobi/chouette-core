module JourneyPatternControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
    end

    class_methods do
      def collection_type(_)
        :journey_patterns
      end
    end
  end
end
