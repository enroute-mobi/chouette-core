# frozen_string_literal: true

module Import
  # Insert Routes and their Journey Patterns into a Referential (via ReferentialInserter).
  class RouteInserter
    def initialize(referential_inserter, on_invalid: nil, on_save: nil)
      @referential_inserter = referential_inserter
      @invalid_handler = on_invalid
      @save_handler = on_save
    end

    attr_reader :referential_inserter

    def valid?(model)
      if model.valid?
        true
      else
        @invalid_handler&.call model
        false
      end
    end

    def saved(model)
      @save_handler&.call model
    end

    def insert(route) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      return unless valid? route

      referential_inserter.routes << route

      route.stop_points.each do |stop_point|
        stop_point.route_id = route.id
        referential_inserter.stop_points << stop_point
      end

      insert_codes route

      route.journey_patterns.each do |journey_pattern|
        journey_pattern.route_id = route.id
        insert_journey_pattern journey_pattern
      end

      saved route
    end

    alias << insert

    def insert_codes(resource)
      resource.codes.each do |code|
        code.resource = resource
        referential_inserter.codes << code
      end
    end

    def insert_journey_pattern(journey_pattern)
      return unless valid? journey_pattern

      referential_inserter.journey_patterns << journey_pattern

      journey_pattern.journey_pattern_stop_points.each do |journey_pattern_stop_point|
        journey_pattern_stop_point.journey_pattern_id = journey_pattern.id
        journey_pattern_stop_point.stop_point_id = journey_pattern_stop_point.stop_point.id

        referential_inserter.journey_pattern_stop_points << journey_pattern_stop_point
      end

      insert_codes journey_pattern

      saved journey_pattern
    end
  end
end
