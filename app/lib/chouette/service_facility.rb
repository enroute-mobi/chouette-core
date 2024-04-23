# frozen_string_literal: true

module Chouette
  class ServiceFacility
    attr_reader :category, :sub_category

    def initialize(category, sub_category=nil)
      @category = category&.to_sym
      @sub_category = sub_category&.to_sym
    end

    def category_human_name(locale: I18n.default_locale)
      I18n.translate category, scope: 'service_facilities.categories', locale: locale
    end

    def sub_category_human_name(locale: I18n.default_locale)
      I18n.translate sub_category, scope: ['service_facilities', category], locale: locale
    end
    alias short_human_name sub_category_human_name

    def human_name(locale: I18n.default_locale, separator: ' - ')
      return unless valid?

      [].tap do |parts|
        parts << category_human_name(locale: locale)
        parts << sub_category_human_name(locale: locale) if sub_category
      end.join(separator)
    end

    def code
      [category, sub_category].compact.join('/')
    end
    alias to_s code

    def self.from(code)
      return if code.blank?

      new(*code.split('/'))
    end

    def valid?
      self.class.category_candidates.include?(category) &&
        (sub_category.nil? || sub_category_candidates.include?(sub_category))
    end

    def sub_categories
      sub_category_candidates.map do |candidate|
        self.class.new category, candidate
      end
    end

    def self_and_sub_categories
      [self, *sub_categories]
    end

    def self.categories(except: [])
      except = except.map(&:to_sym)
      (category_candidates - except).map { |candidate| new candidate }
    end

    private

    def sub_category_candidates
      self.class.definitions[category] || []
    end

    class << self
      def category_candidates
        @category_candidates ||= definitions.keys.freeze
      end

      def definitions
        DEFINITIONS
      end
    end

    DEFINITIONS = {
      accessibility_info: %i[
        audio_information
        audio_for_hearing_impaired
        visual_displays
        displays_for_visually_impaired
        large_print_timetables
        other
      ],
      mobility: %i[
        unknown
        low_floor
        step_free_access
        suitable_for_wheelchairs
        suitable_for_heaviliy_disabled
        boarding_assistance
        onboard_assistance
        unaccompanied_minor_assistance
        tactile_platform_edges
        tactile_guiding_strips
      ],
      passenger_information: %i[
        next_stop_indicator
        stop_announcements
        passenger_information_display
        real_time_connections
        other
      ],
      safety: %i[
        cc_tv
        mobile_coverage
        sos_points
        staffed
      ],
      access: %i[
        unknown
        lift
        wheelchair_lift
        escalator
        travelator
        ramp
        automatic_ramp
        steps
        stairs
        sliding_step
        shuttle
        narrow_entrance
        barrier
        low_floor_access
        validator
      ],
      vehicle_access: %i[
        unknown
        wheelchair_lift
        manual_ramp
        automatic_ramp
        steps
        sliding_step
        narrow_entrance
        validator
      ],
      accessibility_tool: %i[
        wheelchair
        walkingstick
        audio_navigator
        visual_navigator
        passenger_cart
        pushchair
        umbrella
        buggy
        other
      ],
      accommodation_access: %i[
        other
        free_seating
        reservation
        standing
      ],
      accommodation: %i[
        unknown
        seating
        sleeper
        single_sleeper
        double_sleeper
        special_sleeper
        couchette
        single_couchette
        double_couchette
        special_seating
        reclining_seats
        baby_compartment
        family_carriage
        recreation_area
        panorama_coach
        pullman_coach
        standing
      ],
      assistance: %i[
        personal_assistance
        boarding_assistance
        wheelchair_assistance
        unaccompanied_minor_assistance
        wheelchair_use
        conductor
        information
        other
        none
        any
      ],
      assistance_availability: %i[
        none
        available
        available_if_booked
        available_at_certain_times
        unknown
      ],
      berth: %i[
        upper
        lower
        both
      ],
      boarding_permission: %i[
        normal
        early_boarding_possible_before_departure
        late_alighting_possible_after_arrival
        overnight_stay_onboard_allowed
      ],
      couchette: %i[
        unknown
        t2
        t3
        c1
        c2
        c3
        c4
        c5
        c6
        wheelchair
        other
      ],
      emergency: %i[
        police
        fire
        first_aid
        sos_point
        other
      ],
      family: %i[
        none
        services_for_children
        services_for_army_families
        nursery_service
      ],
      gender: %i[
        female
        male
        unspecified
      ],
      hire: %i[
        unknown
        scooter_hire
        vehicle_hire
        car_hire
        motor_cycle_hire
        cycle_hire
        taxi
        boat_hire
        recreation_device_hire
        other
      ],
      luggage_carriage: %i[
        unknown
        no_baggage_storage
        baggage_storage
        luggage_racks
        ski_racks
        ski_racks_on_rear
        extra_large_luggage_racks
        baggage_van
        no_cycles
        cycles_allowed
        cycles_allowed_in_van
        cycles_allowed_in_carriage
        cycles_allowed_with_reservation
        vehicle_transport
      ],
      luggage_locker: %i[
        other
        lockers
        oversize_lockers
        left_luggage_counter
        bike_rack
        cloakroom
      ],
      luggage_service: %i[
        other
        left_luggage
        porterage
        free_trolleys
        paid_trolleys
        collect_and_deliver_to_station
        baggage_check_in_check_out
      ],
      meeting_point: %i[
        meeting_point
        group_meeting
        school_meeting_point
        other
      ],
      money: %i[
        other
        cash_machine
        bank
        insurance
        bureau_de_change
      ],
      meal: %i[
        breakfast
        lunch
        dinner
        snack
        drinks
      ],
      nuisance: %i[
        unknown
        smoking
        no_smoking
        family_area
        childfree_area
        animals_allowed
        no_animals
        breastfeeding_friendly
        mobile_phone_use_zone
        mobile_phone_free_zone
      ],
      parking: %i[
        unknown
        car_park
        park_and_ride_park
        motorcycle_park
        cycle_park
        rental_car_park
        coach_park
      ],
      car_service: %i[
        unknown
        valet_parking
        car_wash
        valet_car_wash
        car_valet_clean
        oil_change
        engine_warming
        petrol
        battery_care
        recharging
        tyre_check
        other
      ],
      medical: %i[
        unknown
        defibrillator
        alcohol_test
      ],
      passenger_comms: %i[
        unknown
        free_wifi
        public_wifi
        power_supply_sockets
        telephone
        audio_entertainment
        video_entertainment
        business_services
        internet
        post_office
        post_box
      ],
      passenger_information_equipment: %i[
        timetable_poster
        fare_information
        line_network_plan
        line_timetable
        stop_timetable
        journey_planning
        interactive_kiosk
        information_desk
        network_status
        real_time_disruptions
        real_time_departures
        other
      ],
      catering: %i[
        bar
        bistro
        buffet
        no_food_available
        no_beverages_available
        restaurant
        first_class_restaurant
        trolley
        coffee_shop
        hot_food_service
        self_service
        snacks
        food_vending_machine
        beverage_vending_machine
        mini_bar
        breakfast_in_car
        meal_at_seat
        other
        unknown
      ],
      reserved_space: %i[
        unknown
        lounge
        hall
        meeting_point
        group_point
        reception
        shelter
        seats
      ],
      retail_facility: %i[
        unknown
        food
        newspaper_tobacco
        recreation_travel
        hygiene_health_beauty
        fashion_accessories
        bank_finance_insurance
        cash_machine
        currency_exchange
        tourism_service
        photo_booth
      ],
      staffing: %i[
        full_time
        part_time
        unmanned
      ],
      ticketing: %i[
        unknown
        ticket_machines
        ticket_office
        ticket_on_demand_machines
        mobile_ticketing
      ],
      scope_of_ticket: %i[
        unknown
        local_ticket
        national_ticket
        international_ticket
      ],
      vehicle_loading: %i[
        none
        loading
        unloading
        additional_loading
        additiona_unloading
        additional_unloading
        unknown
      ]
    }.tap { |d| d.each { |type, restrictions| [type, restrictions.freeze] } }.freeze
  end
end
