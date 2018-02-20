module Chouette
  class VehicleJourneyAtStop < ActiveRecord
    include Chouette::ForBoardingEnumerations
    include Chouette::ForAlightingEnumerations
    include ChecksumSupport

    DAY_OFFSET_MAX = 1

    # FIXME http://jira.codehaus.org/browse/JRUBY-6358
    self.primary_key = "id"

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

    def day_offset_must_be_within_range
      if day_offset_outside_range?(arrival_day_offset)
        errors.add(
          :arrival_day_offset,
          I18n.t(
            'vehicle_journey_at_stops.errors.day_offset_must_not_exceed_max',
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: DAY_OFFSET_MAX + 1
          )
        )
      end

      if day_offset_outside_range?(departure_day_offset)
        errors.add(
          :departure_day_offset,
          I18n.t(
            'vehicle_journey_at_stops.errors.day_offset_must_not_exceed_max',
            short_id: vehicle_journey&.get_objectid&.short_id,
            max: DAY_OFFSET_MAX + 1
          )
        )
      end
    end

    def day_offset_outside_range?(offset)
      # At-stops that were created before the database-default of 0 will have
      # nil offsets. Handle these gracefully by forcing them to a 0 offset.
      offset ||= 0

      offset < 0 || offset > DAY_OFFSET_MAX
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

    def departure_local_time
      local_time departure_time
    end

    def arrival_local_time
      local_time arrival_time
    end

    def departure_local
      format_time departure_local_time
    end

    def arrival_local
      format_time arrival_local_time
    end

    private
    def local_time time
      return unless time
      return time unless stop_point&.stop_area&.time_zone.present?
      return time unless ActiveSupport::TimeZone[stop_point.stop_area.time_zone].present?
      time + ActiveSupport::TimeZone[stop_point.stop_area.time_zone].utc_offset
    end

    def format_time time
      time.strftime "%H:%M" if time
    end

  end
end
