module GenericAttributeControl
  class Presence < ComplianceControl
    include GenericAttributeControl::InternalBaseInterface
    
    class << self
      def attribute_type; nil end
      def default_code; "3-Generic-2" end

      def compliance_test(compliance_check, object)
        object.send(
          model_attribute(compliance_check).name
        ).present?
      end

      def custom_message_attributes(compliance_check, object)
        model_attribute = model_attribute(compliance_check)
        
        i18n_object_type = model_attribute.klass.ts
        i18n_field_name = model_attribute.klass.tmf(model_attribute.name)

        {
          source_objectid: object.objectid,
          object_type: i18n_object_type,
          field_name: i18n_field_name
        }
      end
    end
  end
end
