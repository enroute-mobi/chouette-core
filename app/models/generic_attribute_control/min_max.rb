module GenericAttributeControl
  class MinMax < ComplianceControl

    class << self
      def attribute_type; :integer end
      def default_code; "3-Generic-2" end
    end

    extend HstoreAtts
    hstore_attr :control_attributes, :minimum, validate: true, allow_nil: true
    hstore_accessor :control_attributes, maximum: :integer, target: :string

    validates :maximum, numericality: true, allow_nil: true
    validates :target, presence: true
    include MinMaxValuesValidation

  end
end
