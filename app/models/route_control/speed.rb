module RouteControl
  class Speed < ComplianceControl

    hstore_accessor :control_attributes, minimum: :integer, maximum: :integer

    def self.default_code; "3-VehicleJourney-2" end
  end
end
