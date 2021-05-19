module GenericAttributeControl
  class Pattern < ComplianceControl
    store_accessor :control_attributes, :pattern, :target

    validates :target, presence: true
    validates :pattern, presence: true

    class << self
      def attribute_type; :string end
      def default_code; "3-Generic-1" end
    end
  end
end
