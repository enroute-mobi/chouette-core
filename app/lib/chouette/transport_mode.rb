# frozen_string_literal: true

module Chouette
  class TransportMode
    attr_reader :mode, :sub_mode

    def initialize(mode, sub_mode = nil)
      self.mode = mode&.to_sym
      self.sub_mode = sub_mode&.to_sym
    end

    def mode_human_name(locale: I18n.default_locale)
      I18n.translate mode, scope: 'transport_modes.modes', locale: locale
    end

    def sub_mode_human_name(locale: I18n.default_locale)
      I18n.translate mode, scope: ['transport_modes.sub_modes', mode], locale: locale
    end

    def human_name(locale: I18n.default_locale, separator: ' / ')
      return unless valid?

      [].tap do |parts|
        parts << mode_human_name(locale: locale)
        parts << sub_mode_human_name(locale: locale) if sub_mode
      end.join(separator)
    end

    def code
      [mode, sub_mode].compact.join('/')
    end
    alias to_s code

    def self.from(code)
      new(*code.split('/'))
    end

    def inspect
      "##{self}"
    end

    def valid?
      self.class.mode_candidates.include?(mode) &&
        (sub_mode.nil? || sub_mode_candidates.include?(sub_mode))
    end

    def sub_modes
      sub_mode_candidates.map do |candidate|
        self.class.new mode, candidate
      end
    end

    def self.modes(except: [])
      except = except.map(&:to_sym)
      (mode_candidates - except).map { |candidate| new candidate }
    end

    private

    def sub_mode_candidates
      self.class.definitions[mode]
    end

    def self.mode_candidates
      @mode_candidates ||= definitions.keys.freeze
    end

    def self.definitions
      DEFINITIONS
    end

    DEFINITIONS = {
      metro: %i[
        metro
        tube
        urban_railway
      ],
      funicular: %i[
        all_funicular_services
        funicular
      ],
      tram: %i[
        city_tram
        local_tram
        regional_tram
        shuttle_tram
        sightseeing_tram
        tram_train
      ],
      rail: %i[
        car_transport_rail_service
        cross_country_rail
        high_speed_rail
        international
        interregional_rail
        local
        long_distance
        night_train
        rack_and_pinion_railway
        rail_shuttle
        regional_rail
        replacement_rail_service
        sleeper_rail_service
        special_train
        suburban_railway
        tourist_railway
        train_tram
      ],
      coach: %i[
        commuter_coach
        international_coach
        national_coach
        regional_coach
        shuttle_coach
        sightseeing_coach
        special_coach
        tourist_coach
      ],
      bus: %i[
        airport_link_bus
        demand_and_response_bus
        express_bus
        high_frequency_bus
        local_bus
        mobility_bus_for_registered_disabled
        mobility_bus
        night_bus
        post_bus
        rail_replacement_bus
        regional_bus
        school_and_public_service_bus
        school_bus
        shuttle_bus
        sightseeing_bus
        special_needs_bus
      ],
      water: %i[
        international_car_ferry
        national_car_ferry
        regional_car_ferry
        local_car_ferry
        international_passenger_ferry
        national_passenger_ferry
        regional_passenger_ferry
        local_passenger_ferry
        post_boat
        train_ferry
        road_ferry_link
        airport_boat_link
        high_speed_vehicle_service
        high_speed_passenger_service
        sightseeing_service
        school_boat
        cable_ferry
        river_bus
        scheduled_ferry
        shuttle_ferry_service
      ],
      telecabin: %i[
        cable_car
        chair_lift
        drag_lift
        lift
        telecabin_link
        telecabin
      ],
      air: %i[
        airship_service
        domestic_charter_flight
        domestic_flight
        domestic_scheduled_flight
        helicopter_service
        intercontinental_charter_flight
        intercontinental_flight
        international_charter_flight
        international_flight
        round_trip_charter_flight
        schengen_area_flight
        short_haul_international_flight
        shuttle_flight
        sightseeing_flight
      ],
      hire_car: %i[
        all_hire_vehicles
        hire_car
        hire_cycle
        hire_motorbike
        hire_van
      ],
      taxi: %i[
        all_taxi_services
        bike_taxi
        black_cab
        communal_taxi
        mini_cab
        rail_taxi
        water_taxi
      ]
    }.tap { |d| d.each { |mode, sub_modes| [mode, sub_modes.freeze] } }.freeze
  end
end
