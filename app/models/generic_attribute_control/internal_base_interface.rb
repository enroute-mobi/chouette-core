module GenericAttributeControl
  module InternalBaseInterface
    extend ActiveSupport::Concern

    included do
      include ComplianceControls::InternalControlInterface
      
      store_accessor :control_attributes, :target

      validates :target, presence: true

      class << self
        def self.collection_type(compliance_check)
          resource_name(compliance_check).pluralize.to_sym
        end

        private

        def resource_name(compliance_check)
          compliance_check.target.split('#').first
        end

        def attribute_name(compliance_check)
          compliance_check.target.split('#').last
        end
      end
    end
  end
end
