module GenericAttributeControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      store_accessor :control_attributes, :target

      validates :target, presence: true
    end

    class_methods do
      def collection_type(compliance_check)
        resource_name(compliance_check).pluralize.to_sym
      end

      def resource_name compliance_check
        compliance_check.target.split('#').first
      end

      def collection_type(_)
        :vehicle_journeys
      end

      def label_attr(compliance_check)
        :published_journey_name
      end
    end
  end
end
