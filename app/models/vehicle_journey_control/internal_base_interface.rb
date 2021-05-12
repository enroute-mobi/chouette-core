module VehicleJourneyControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
    end

    class_methods do
      def collection_type(_)
        :vehicle_journeys
      end

      def label_attr(compliance_check)
        :published_journey_name
      end
    end
  end
end
