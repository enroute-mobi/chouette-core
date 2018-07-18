module JourneyPatternControl
  class MinimumLength < InternalControl::Base
    required_features :core_controls

    enumerize :criticity, in: %i(error), scope: true, default: :error

    MINIMUM_LENGTH = 2

    def self.default_code; "3-JourneyPattern-3" end

    def self.object_path compliance_check, journey_pattern
      referential_line_route_journey_patterns_collection_path(journey_pattern.referential, journey_pattern.route.line, journey_pattern.route)
    end

    def self.collection referential
      referential.journey_patterns
    end

    def self.compliance_test compliance_check, journey_pattern
      journey_pattern.stop_points.length >= MINIMUM_LENGTH
    end
  end
end
