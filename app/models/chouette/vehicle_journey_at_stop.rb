module Chouette
  class VehicleJourneyAtStop < ActiveRecord
    include Chouette::ForBoardingEnumerations
    include Chouette::ForAlightingEnumerations
    include ChecksumSupport

    DAY_OFFSET_MAX = 2

    @@day_offset_max = DAY_OFFSET_MAX
    mattr_accessor :day_offset_max

    belongs_to :stop_point
    belongs_to :vehicle_journey

    attr_accessor :_destroy, :dummy

    validate :arrival_must_be_before_departure
    def arrival_must_be_before_departure
      # security against nil values
      return unless arrival_time && departure_time

      if TimeDuration.exceeds_gap?(4.hours, arrival_time, departure_time)
        errors.add(
          :arrival_time,
          I18n.t("activerecord.errors.models.vehicle_journey_at_stop.arrival_must_be_before_departure")
        )
      end
    end

    validate :day_offset_must_be_within_range

    after_initialize :set_virtual_attributes
    def set_virtual_attributes
      @_destroy = false
      @dummy = false
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

    def day_offset_must_be_within_range
      if day_offset_outside_range?(arrival_day_offset)
        errors.add(
          :arrival_day_offset,
          I18n.t(
            'vehicle_journey_at_stops.errors.day_offset_must_not_exceed_max',
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: Chouette::VehicleJourneyAtStop.day_offset_max + 1
          )
        )
      end

      if day_offset_outside_range?(departure_day_offset)
        errors.add(
          :departure_day_offset,
          I18n.t(
            'vehicle_journey_at_stops.errors.day_offset_must_not_exceed_max',
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: Chouette::VehicleJourneyAtStop.day_offset_max + 1
          )
        )
      end
    end

    def day_offset_outside_range?(offset)
      # At-stops that were created before the database-default of 0 will have
      # nil offsets. Handle these gracefully by forcing them to a 0 offset.
      offset ||= 0

      offset < 0 || offset > Chouette::VehicleJourneyAtStop.day_offset_max
    end

    def checksum_attributes(db_lookup = true)
      [].tap do |attrs|
        [self.departure_time, self.arrival_time].each do |time|
          time = time&.utc
          time = time && "%.2d:%.2d" % [time.hour, time.min]
          attrs << time
        end
        attrs << self.departure_day_offset.to_s
        attrs << self.arrival_day_offset.to_s
        attrs << self.stop_area_id.to_s if self.stop_area_id.present? 
      end
    end

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
      handle_midnight(departure_time).in_time_zone(time_zone).change(day: 1)
    end

    def arrival_time_with_zone
      handle_midnight(arrival_time).in_time_zone(time_zone).change(day: 1)
    end

    def time_zone
      ActiveSupport::TimeZone[stop_point&.stop_area_light&.time_zone || "UTC"]
    end

    def time_zone_offset
      return 0 unless stop_point&.stop_area_light&.time_zone.present?
      time_zone&.utc_offset || 0
    end

    private
    def local_time time, offset=nil
      return nil unless time
      (handle_midnight(time) + (offset || time_zone_offset)).utc
    end

    def format_time time
      time.strftime "%H:%M" if time
    end

    def handle_midnight time
      # This handle tyhe very specific case whare a stop time equals to midnight UTC
      # For example, if a cours has the following times in Los Angeles (UTC-8):
      # 15:00, 16:00
      # Once converted in UTC, we get:
      # 01/01/2000 23:00, 01/01/2000 00:00
      # When converted back with the TZ, we obtain:
      # 01/01/2000 15:00, 31/12/1999 16:00
      # Thus, we have to cheat to keep the stops in the right sequence

      return time if time_zone_offset == 0

      time += 1.day if time.hour == 0
      time
    end
  end
end
