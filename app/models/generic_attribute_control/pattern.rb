module GenericAttributeControl
  class Pattern < ComplianceControl
    hstore_accessor :control_attributes, value: :string, pattern: :string

    validate :pattern_match
    def pattern_match
      true
    end

    class << self
      def default_criticity; :warning end
      def default_code; "3-Generic-3" end
    end
  end
end
