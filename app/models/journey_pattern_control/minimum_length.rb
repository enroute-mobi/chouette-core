module JourneyPatternControl
  class MinimumLength < ComplianceControl
    include JourneyPatternControl::InternalBaseInterface

    MINIMUM_LENGTH = 2

    def self.default_code; "3-JourneyPattern-3" end

    def self.compliance_test(_, journey_pattern)
      journey_pattern.stop_points.length >= MINIMUM_LENGTH
    end
  end
end
