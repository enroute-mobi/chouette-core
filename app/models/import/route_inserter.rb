# frozen_string_literal: true

module Import
  # Insert Routes and their Journey Patterns into a Referential (via ReferentialInserter).
  class RouteInserter < Inserter
    def insert(route) # rubocop:disable Metrics/MethodLength
      referential_inserter.routes << route

      route.stop_points.each do |stop_point|
        stop_point.route = route
        referential_inserter.stop_points << stop_point
      end

      route.journey_patterns.each do |journey_pattern|
        journey_pattern.route = route
        journey_pattern_inserter.insert journey_pattern
      end
    end

    def journey_pattern_inserter
      @journey_pattern_inserter ||= Import::JourneyPatternInserter.new(
        referential_inserter, on_invalid: invalid_handler, on_save: save_handler
      )
    end
  end

  class JourneyPatternInserter < Inserter
    def insert(journey_pattern)
      referential_inserter.journey_patterns << journey_pattern

      journey_pattern.journey_pattern_stop_points.each do |journey_pattern_stop_point|
        journey_pattern_stop_point.journey_pattern = journey_pattern
        # stop_point is reassigned to update stop_point_id
        journey_pattern_stop_point.stop_point = journey_pattern_stop_point.stop_point # rubocop:disable Lint/SelfAssignment

        referential_inserter.journey_pattern_stop_points << journey_pattern_stop_point
      end
    end
  end
end
