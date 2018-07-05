module Chouette
  class VehicleJourneyAtStopsDayOffset
    def initialize(at_stops)
      @at_stops = at_stops
    end

    def calculate!
      offset = 0
      @at_stops.select{|s| s.arrival_time.present? && s.departure_time.present? }.inject(nil) do |prior_stop, stop|
        if prior_stop.nil?
          stop.departure_day_offset = 0
          stop.arrival_day_offset = 0
          next stop
        end

        stop_arrival_time = stop.arrival_time_with_zone
        prior_stop_departure_time = prior_stop.departure_time_with_zone

        # Compare Time with Zone 23:00 +001 with 00:05 +002
        if stop_arrival_time < prior_stop_departure_time
          offset += 1
        end

        stop.arrival_day_offset = offset

        # Compare '23:00' with '00:05' for example
        if stop.departure_local < stop.arrival_local
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
