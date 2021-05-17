module GenericAttributeControl
  class Presence < ComplianceControl
    include GenericAttributeControl::InternalBaseInterface
    
    class << self
      def attribute_type; nil end
      def default_code; "3-Generic-2" end

      def compliance_test(compliance_check, object)
        object.send(
          attribute_name(compliance_check)
        ).present?
      end

      def custom_message_attributes(compliance_check, object)
        {
          source_objectid: object.objectid,
          object_type: resource_name(compliance_check),
          field_name: attribute_name(compliance_check)
        }
      end
    end
  end
end
