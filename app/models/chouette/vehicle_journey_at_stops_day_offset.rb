module Chouette
  class VehicleJourneyAtStopsDayOffset
    def initialize(at_stops)
      @at_stops = at_stops
    end

    def calculate!
      arrival_offset = 0
      departure_offset = 0

      @at_stops.inject(nil) do |prior_stop, stop|
        next stop if prior_stop.nil?

        # we only compare time of the day, not actual times
        stop_arrival_time = stop.arrival_time - stop.arrival_time.to_date.to_time
        stop_departure_time = stop.departure_time - stop.departure_time.to_date.to_time
        prior_stop_arrival_time = prior_stop.arrival_time - prior_stop.arrival_time.to_date.to_time
        prior_stop_departure_time = prior_stop.departure_time - prior_stop.departure_time.to_date.to_time

        if stop_arrival_time < prior_stop_departure_time ||
            stop_arrival_time < prior_stop_arrival_time
          arrival_offset += 1
        end

        if stop_departure_time < stop_arrival_time ||
            stop_departure_time < prior_stop_departure_time
          departure_offset += 1
        end

        stop.arrival_day_offset = arrival_offset
        stop.departure_day_offset = departure_offset

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
