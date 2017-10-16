module GenericAttributeControl
  class MinMax < ComplianceControl
    hstore_accessor :control_attributes, minimum: :integer, maximum: :integer, target: :string

    validates :minimum, numericality: true, allow_nil: true
    validates :maximum, numericality: true, allow_nil: true
    #validates :target, presence: true
    include MinMaxValuesValidation

    class << self
      def attribute_type; :integer end
      def default_criticity; :warning end
      def default_code; "3-Generic-2" end
    end
  end
end
