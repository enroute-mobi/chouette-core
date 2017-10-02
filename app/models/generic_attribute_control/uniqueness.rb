module GenericAttributeControl
  class Uniqueness < ComplianceControl
    hstore_accessor :control_attributes, name: :string

    validate :unique_values
    def unique_values
      true
    end

    class << self
      def default_criticity; :warning end
      def default_code; "3-Generic-3" end
    end
  end
end
