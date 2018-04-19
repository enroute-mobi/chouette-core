module Chouette
  class VehicleJourneyAtStopsDayOffset
    def initialize(at_stops)
      @at_stops = at_stops
    end

    def time_from_fake_date fake_date
      return unless fake_date.present?
      fake_date - fake_date.to_date.to_time
    end

    def calculate!
      offset = 0
      tz_offset = @at_stops.first&.time_zone_offset
      @at_stops.select{|s| s.arrival_time.present? && s.departure_time.present? }.inject(nil) do |prior_stop, stop|
        next stop if prior_stop.nil?

        # we only compare time of the day, not actual times
        stop_arrival_time = time_from_fake_date stop.arrival_local_time(tz_offset)
        stop_departure_time = time_from_fake_date stop.departure_local_time(tz_offset)
        prior_stop_departure_time = time_from_fake_date prior_stop.departure_local_time(tz_offset)

        if stop_arrival_time < prior_stop_departure_time
          offset += 1
        end

        stop.arrival_day_offset = offset

        if stop_departure_time < stop_arrival_time
          offset += 1
        end

        stop.departure_day_offset = offset

        stop
      end
    end

    def save
      @at_stops.each do |at_stop|
        at_stop.save
      end
    end

    def update
      calculate!
      save
    end
  end
end
