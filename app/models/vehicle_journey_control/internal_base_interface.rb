module VehicleJourneyControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface

      def self.collection_type(_)
        :vehicle_journeys
      end

      def self.label_attr(_)
        :published_journey_name
      end
    end
  end
end
