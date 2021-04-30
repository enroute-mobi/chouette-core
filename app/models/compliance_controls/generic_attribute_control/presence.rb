module GenericAttributeControl
  class Presence < ComplianceControl
    store_accessor :control_attributes, :target

    validates :target, presence: true

    class << self
      def attribute_type; nil end
      def default_code; "3-Generic-4" end
    end
  end
end
