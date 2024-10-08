# frozen_string_literal: true

module Chouette
  class TransportMode
    attr_reader :mode, :sub_mode

    def initialize(mode, sub_mode = nil)
      @mode = mode&.to_sym
      @sub_mode = sub_mode&.to_sym
    end

    def without_sub_mode
      TransportMode.new(mode)
    end

    def mode_human_name(locale: I18n.locale)
      I18n.translate mode, scope: 'transport_modes.modes', locale: locale
    end

    def sub_mode_human_name(locale: I18n.locale)
      I18n.translate sub_mode, scope: ['transport_modes', mode], locale: locale
    end

    def human_name(locale: I18n.locale, separator: ' / ')
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
      return if code.blank?

      new(*code.to_s.split('/'))
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

    def self_and_sub_modes
      [self, *sub_modes]
    end

    def self.modes(except: [])
      except = except.map(&:to_sym)
      (mode_candidates - except).map { |candidate| new candidate }
    end

    def self.sorted_modes(**options)
      modes(**options).map { |m| [m.mode_human_name, m.code] }.sort_by(&:first)
    end

    def camelize_mode
      return unless mode

      String(mode).camelize(:lower)
    end

    def camelize_sub_mode
      return unless sub_mode

      String(sub_mode).camelize(:lower)
    end

    def eql?(other)
      other && mode == other.mode && sub_mode == other.sub_mode
    end

    def hash
      @hash ||= [mode, sub_mode].hash
    end

    def self.mapper(&block)
      Chouette::TransportMode::Mapper.new(&block)
    end

    private

    def sub_mode_candidates
      self.class.definitions[mode] || []
    end

    class << self
      def mode_candidates
        @mode_candidates ||= definitions.keys.freeze
      end

      def definitions
        DEFINITIONS
      end
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
        street_cable_car
      ],
      tram: %i[
        city_tram
        local_tram
        regional_tram
        shuttle_tram
        sightseeing_tram
        train_tram
        tram_train
      ],
      rail: %i[
        airport_link_rail
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
        monorail
      ],
      coach: %i[
        all_coach_services
        commuter_coach
        international_coach
        national_coach
        regional_coach
        shuttle_coach
        sightseeing_coach
        school_coach
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
        dedicated_lane_bus
        nekobasu
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
        canal_barge
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
      taxi: %i[
        all_taxi_services
        app_taxi
        bike_taxi
        black_cab
        communal_taxi
        charter_taxi
        cycle_rickshaw
        fiacre
        mini_cab
        rail_taxi
        rickshaw
        water_taxi
      ],
      self_drive: %i[
        all_hire_vehicles
        all_vehicles
        hire_scooter
        hire_car
        hire_van
        hire_motorbike
        hire_cycle
        own_scooter
        own_cycle
        own_motorbike
        own_car
        own_van
      ],
      snow_and_ice: %i[
        snow_mobile
        snow_cat
        snow_coach
        terra_bus
        wind_sled
      ],
      trolley_bus: []
    }.tap { |d| d.each { |mode, sub_modes| [mode, sub_modes.freeze] } }.freeze

    # Simplifying mapping between a transport mode and a value
    #
    #   mapper = Chouette::TransportMode.mapper do
    #     register 'bus', 'Bus'
    #     register 'bus/school_bus', 'School Bus'
    #   end
    #
    #   mapper.for('bus/school_bus') => 'School Bus'
    #   mapper.for('bus') => 'Bus'
    #   mapper.for('bus/night_bus') => 'Bus'
    #
    # A mapper can be forked:
    #
    #   extended = mapper.append do
    #     register 'bus', 'New'
    #     register 'bus/night_bus', 'Night Bus'
    #   end
    #
    #   extended.for('bus') => 'New'
    #   extended.for('bus/night_bus') => 'Night Bus'
    #
    class Mapper
      def initialize(&block)
        setup(&block) if block_given?
      end

      def setup(&block)
        instance_exec(&block)
      end

      def append(&block)
        clone.tap { |cloned| cloned.setup(&block) }
      end

      def initialize_clone(other)
        @mappings = other.mappings.dup
      end

      def mappings
        @mappings ||= {}
      end

      def register(transport_mode, value)
        transport_mode = from(transport_mode)
        mappings[transport_mode] = value
      end

      def for(transport_mode)
        transport_mode = from(transport_mode)
        mappings[transport_mode] || mappings[transport_mode.without_sub_mode]
      end

      private

      def from(transport_mode)
        return transport_mode if transport_mode.is_a?(Chouette::TransportMode)

        Chouette::TransportMode.from(transport_mode)
      end
    end

    class Type < ::ActiveRecord::Type::Value
      def cast(value)
        return if value.blank?

        TransportMode.from(value) if value.is_a?(String)
      end

      def serialize(value)
        return if value.blank?

        value.code
      end
    end
  end
end
