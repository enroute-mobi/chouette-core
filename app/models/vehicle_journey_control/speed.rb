module VehicleJourneyControl
  class Speed < ComplianceControl
    store_accessor :control_attributes, :minimum, :maximum

    include MinMaxValuesValidation

    def self.default_code; "3-VehicleJourney-2" end
  end
end
