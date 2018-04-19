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

    delegate :registration_number, to: :stop_point

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

    def checksum_attributes
      [].tap do |attrs|
        attrs << self.departure_time&.utc.try(:to_s, :time)
        attrs << self.arrival_time&.utc.try(:to_s, :time)
        attrs << self.departure_day_offset.to_s
        attrs << self.arrival_day_offset.to_s
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

    def time_zone_offset
      return 0 unless stop_point&.stop_area&.time_zone.present?
      ActiveSupport::TimeZone[stop_point.stop_area.time_zone]&.utc_offset || 0
    end

    private
    def local_time time, offset=nil
      return nil unless time
      time + (offset || time_zone_offset)
    end

    def format_time time
      time.strftime "%H:%M" if time
    end

  end
end
