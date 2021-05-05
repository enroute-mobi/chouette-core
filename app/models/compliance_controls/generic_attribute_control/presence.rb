require_dependency 'compliance_controls/generic_attribute_control/internal_base'

module GenericAttributeControl
  class Presence < InternalBase
    

    class << self
      def attribute_type; nil end
      def default_code; "3-Generic-4" end

      def compliance_test(compliance_check, object)
        object.send(
          attribute_name(compliance_check)
        ).present?
      end
    end
  end
end
