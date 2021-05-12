module JourneyPatternControl
  class MinMaxDistanceCost < ComplianceControl
    include JourneyPatternControl::InternalBaseInterface
    include JourneyPatternControl::MinMaxCostInterface

    def self.default_code; "3-JourneyPattern-4" end
  end
end
