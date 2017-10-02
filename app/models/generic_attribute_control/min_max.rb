module GenericAttributeControl
  class MinMax < ComplianceControl
    hstore_accessor :control_attributes, minimum: :integer, maximum: :integer


    validate :min_max_values
    def min_max_values
      true
    end

    class << self
      def default_criticity; :warning end
      def default_code; "3-Generic-2" end
      def dynamic_attributes
        hstore_metadata_for_control_attributes.keys
      end
    end
  end
end
