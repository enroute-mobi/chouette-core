module VehicleJourneyControl
  class Speed < ComplianceControl
    hstore_accessor :control_attributes, minimum: :integer, maximum: :integer

    validates :minimum, numericality: true, allow_nil: true
    validates :maximum, numericality: true, allow_nil: true
    include MinMaxValuesValidation

    def self.default_code; "3-VehicleJourney-2" end
  end
end
