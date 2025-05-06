# frozen_string_literal: true

module Chouette
  class VehicleJourneyAtStop < Referential::ActiveRecord
    include ChecksumSupport

    include Chouette::ForBoardingEnumerations
    include Chouette::ForAlightingEnumerations

    DAY_OFFSET_MAX = 2

    @@day_offset_max = DAY_OFFSET_MAX
    mattr_accessor :day_offset_max

    belongs_to :stop_area, optional: true # CHOUETTE-3247
    belongs_to :stop_point # TODO: CHOUETTE-3247 optional: true?
    belongs_to :vehicle_journey, inverse_of: :vehicle_journey_at_stops # TODO: CHOUETTE-3247 optional: true?

    attr_accessor :_destroy, :dummy

    concerning :Validations do # rubocop:disable Metrics/BlockLength
      included do
        validate :arrival_must_be_before_departure, unless: :flexible?
        validate :earliest_departure_time_of_day_must_be_before_latest_arrival_time_of_day, if: :flexible?

        validate :day_offset_must_be_within_range
      end

      private

      def flexible?
        earliest_departure_time_of_day.present? || latest_arrival_time_of_day.present?
      end

      def arrival_must_be_before_departure
        return unless arrival_time_of_day && departure_time_of_day
        return if arrival_time_of_day <= departure_time_of_day

        errors.add(:arrival_time, :arrival_must_be_before_departure)
      end

      def earliest_departure_time_of_day_must_be_before_latest_arrival_time_of_day
        return unless earliest_departure_time_of_day && latest_arrival_time_of_day
        return if earliest_departure_time_of_day < latest_arrival_time_of_day

        errors.add(:earliest_departure_time_of_day, :arrival_must_be_before_departure)
      end

      def day_offset_must_be_within_range
        if day_offset_outside_range?(arrival_day_offset)
          errors.add(
            :arrival_day_offset,
            :day_offset_must_not_exceed_max,
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: day_offset_max
          )
        end

        if day_offset_outside_range?(departure_day_offset)
          errors.add(
            :departure_day_offset,
            :day_offset_must_not_exceed_max,
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: day_offset_max
          )
        end
      end
    end

    after_initialize :set_virtual_attributes
    def set_virtual_attributes
      @_destroy = false
      @dummy = false
    end

    def departure_time_of_day
      @departure_time_of_day ||= TimeOfDay.unserialize(attributes_before_type_cast["departure_time"], day_offset: departure_day_offset)
    end

    def departure_local_time_of_day
      @departure_local_time_of_day ||= departure_time_of_day&.with_utc_offset(time_zone_offset)
    end

    def departure_time_of_day=(time_of_day)
      time_of_day = time_of_day.without_utc_offset
      @departure_time_of_day = time_of_day
      @departure_local_time_of_day = nil

      self.departure_time = time_of_day.to_hms
      self.departure_day_offset = time_of_day.day_offset
    end

    def arrival_time_of_day
      @arrival_time_of_day ||= TimeOfDay.unserialize(attributes_before_type_cast["arrival_time"], day_offset: arrival_day_offset)
    end

    def arrival_local_time_of_day
      @arrival_local_time_of_day ||= arrival_time_of_day&.with_utc_offset(time_zone_offset)
    end

    def arrival_time_of_day=(time_of_day)
      time_of_day = time_of_day.without_utc_offset
      @arrival_time_of_day = time_of_day
      @arrival_local_time_of_day = nil

      self.arrival_time = time_of_day.to_hms
      self.arrival_day_offset = time_of_day.day_offset
    end

    attribute :earliest_departure_time_of_day, TimeOfDay::Type::SecondOffset.new
    attribute :latest_arrival_time_of_day, TimeOfDay::Type::SecondOffset.new

    def earliest_departure_local_time_of_day
      @earliest_departure_local_time_of_day ||= earliest_departure_time_of_day&.with_utc_offset(time_zone_offset)
    end

    def latest_arrival_local_time_of_day
      @latest_arrival_local_time_of_day ||= latest_arrival_time_of_day&.with_utc_offset(time_zone_offset)
    end

    %i[departure_time arrival_time].each do |attr|
      define_method "#{attr}=" do |val|
        self[attr] = convert_string_time_to_utc_time(val)
      end

      define_method attr do
        self[attr]&.utc
      end

      # departure_local_time=
      # arrival_local_time=
      define_method "#{attr.to_s.split('_').join('_local_')}=" do |local_time|
        self.send "#{attr}=", format_time(local_time(convert_string_time_to_utc_time(local_time), -time_zone_offset))
      end
    end

    def convert_string_time_to_utc_time(val)
      return unless val.present?

      if val && val.is_a?(String)
        tz = Time.zone
        Time.zone = 'UTC'
        val = Time.zone.parse val
        Time.zone = tz
      end
      base_date = '2000/01/01 00:00:00 UTC'.to_time.utc
      base_date.change hour: val.utc.hour, min: val.utc.min, sec: val.sec
    end

    # Compare absolute day offset value with day_offset_max (if defined)
    def day_offset_outside_range?(offset)
      return false if day_offset_max.blank?

      offset ||= 0
      offset < -1 || offset > day_offset_max
    end

    def checksum_attributes(_db_lookup = true)
      [].tap do |attrs|
        [self.departure_time, self.arrival_time].each do |time|
          time = time&.utc
          time = time && "%.2d:%.2d" % [time.hour, time.min]
          attrs << time
        end
        attrs << self.departure_day_offset.to_s
        attrs << self.arrival_day_offset.to_s
        attrs << self.stop_area_id.to_s if self.stop_area_id.present?
        if earliest_departure_time_of_day
          attrs << earliest_departure_time_of_day.second_offset
          attrs << latest_arrival_time_of_day&.second_offset
        end
      end
    end

    attr_writer :raw_time_zone

    def raw_time_zone
      @raw_time_zone ||= stop_point&.stop_area_light&.time_zone
    end

    def time_zone
      ActiveSupport::TimeZone[raw_time_zone || "UTC"]
    end

    def time_zone_offset
      return 0 unless raw_time_zone.present?
      time_zone&.utc_offset || 0
    end

    ########## DEPRECATED ##########
    def departure
      format_time departure_time.utc
    end

    def arrival
      format_time arrival_time.utc
    end

    def departure_local_time offset=nil
      local_time departure_time, offset
    end

    def arrival_local_time offset=nil
      local_time arrival_time, offset
    end
    def departure_local
      format_time departure_local_time
    end

    def arrival_local
      format_time arrival_local_time
    end

    def departure_time_with_zone
      departure_time.in_time_zone(time_zone).change(day: 1)
    end

    def arrival_time_with_zone
      arrival_time.in_time_zone(time_zone).change(day: 1)
    end

    # Reads light VehicleJourneyAtStops for the current scope
    #
    # Uses a database cursor and returns Light::VehicleJourneyAtStop
    def self.find_each_light(**options, &block)
      vehicle_journey_at_stop = Light::VehicleJourneyAtStop.new
      each_row(**options) do |row|
        vehicle_journey_at_stop.attributes = row
        block.call vehicle_journey_at_stop
      end
    end

    module Light
      class VehicleJourneyAtStop
        attr_accessor :id, :vehicle_journey_id, :stop_point_id, :stop_area_id
        attr_accessor :arrival_time, :departure_time, :departure_day_offset, :arrival_day_offset
        attr_accessor :earliest_departure_time_of_day, :latest_arrival_time_of_day
        attr_accessor :checksum, :checksum_source
        attr_accessor :time_zone, :position

        def initialize(attributes = {})
          self.attributes = attributes
        end

        def attributes=(attributes)
          @id = attributes['id']
          @vehicle_journey_id = attributes['vehicle_journey_id']
          @stop_point_id = attributes['stop_point_id']
          @arrival_time = attributes['arrival_time']
          @departure_time = attributes['departure_time']
          @departure_day_offset = attributes['departure_day_offset']
          @arrival_day_offset = attributes['arrival_day_offset']
          @stop_area_id = attributes['stop_area_id']
          @checksum = attributes['checksum']
          @checksum_source = attributes['checksum_source']
          @time_zone = attributes['time_zone']
          @earliest_departure_time_of_day_seconds = attributes['earliest_departure_time_of_day']
          @latest_arrival_time_of_day_seconds = attributes['latest_arrival_time_of_day']
          @position = attributes["position"]

          @attributes = attributes
        end

        def method_missing(name, *args)
          stringified_name = name.to_s
          if @attributes.key?(stringified_name)
            return @attributes[stringified_name]
          end

          super
        end

        def respond_to?(name, *args)
          super || @attributes.key?(name.to_s)
        end

        def arrival_time_of_day
          TimeOfDay.parse(arrival_time, day_offset: arrival_day_offset) if arrival_time
        end

        def arrival_local_time_of_day
          TimeOfDay.parse(arrival_time, day_offset: arrival_day_offset, time_zone: time_zone) if arrival_time
        end

        def departure_time_of_day
          TimeOfDay.parse(departure_time, day_offset: departure_day_offset) if departure_time
        end

        def departure_local_time_of_day
          TimeOfDay.parse(departure_time, day_offset: departure_day_offset, time_zone: time_zone) if departure_time
        end

        def earliest_departure_time_of_day
          return unless @earliest_departure_time_of_day_seconds

          @earliest_departure_time_of_day ||= TimeOfDay.from_second_offset(@earliest_departure_time_of_day_seconds)
        end

        def latest_arrival_time_of_day
          return unless @latest_arrival_time_of_day_seconds

          @latest_arrival_time_of_day ||= TimeOfDay.from_second_offset(@latest_arrival_time_of_day_seconds)
        end
      end
    end

    def self.departures
      departure_query = <<~SQL
        (
          SELECT vehicle_journey_at_stops.*
          FROM #{departure_arrival_base_query}
          WHERE vehicle_journey_at_stops.departure = 'true'
        ) AS vehicle_journey_at_stops
      SQL

      select('*').from(departure_query)
    end

    def self.arrivals
      arrival_query = <<~SQL
        (
          SELECT vehicle_journey_at_stops.*
          FROM #{departure_arrival_base_query}
          WHERE vehicle_journey_at_stops.arrival = 'true'
        ) AS vehicle_journey_at_stops
      SQL

      select('*').from(arrival_query)
    end

    def self.departure_arrival_base_query
      <<~SQL
        (
          SELECT
            vehicle_journey_at_stops.*,
            (LAG(vehicle_journey_at_stops.id) OVER vehicle_journey_stops) IS NULL AS departure,
            (LEAD(vehicle_journey_at_stops.id) OVER vehicle_journey_stops) IS NULL AS arrival
          FROM vehicle_journey_at_stops
          INNER JOIN stop_points ON vehicle_journey_at_stops.stop_point_id = stop_points.id
          WINDOW vehicle_journey_stops AS (
            PARTITION BY vehicle_journey_id
            ORDER BY stop_points.position
          )
        ) vehicle_journey_at_stops
      SQL
    end

    private

    def local_time time, offset=nil
      return nil unless time
      (time + (offset || time_zone_offset)).utc
    end

    def format_time time
      time.strftime "%H:%M" if time
    end
    ################################
  end
end
