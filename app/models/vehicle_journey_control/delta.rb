module VehicleJourneyControl
  class Delta < ComplianceControl

    store_accessor :control_attributes, :maximum

    validates_numericality_of :maximum, allow_nil: true, greater_than_or_equal_to: 0
    validates_presence_of :maximum

    def self.default_code; "3-VehicleJourney-3" end
  end
end
