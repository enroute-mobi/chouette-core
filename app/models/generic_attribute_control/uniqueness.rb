module GenericAttributeControl
  class Uniqueness < ComplianceControl
    store_accessor :control_attributes, :target

    validates :target, presence: true

    class << self
      def attribute_type; :string end
      def default_code; "3-Generic-3" end
    end
  end
end
