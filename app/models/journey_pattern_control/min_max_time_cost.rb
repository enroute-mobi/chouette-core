module JourneyPatternControl
  class MinMaxTimeCost < ComplianceControl
    include JourneyPatternControl::InternalBaseInterface
    include JourneyPatternControl::MinMaxCostInterface

    def self.default_code; "3-JourneyPattern-5" end

    def self.attribute_to_check
      :time
    end
  end
end
