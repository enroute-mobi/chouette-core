module GenericAttributeControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      store_accessor :control_attributes, :target

      validates :target, presence: true

      def self.collection_type(compliance_check)
        resource_name, _ = compliance_check.target.split('#').first
        resource_name.pluralize.to_sym
      end
    end
  end
end
