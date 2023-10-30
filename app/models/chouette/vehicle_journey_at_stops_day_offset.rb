module Chouette
  class VehicleJourneyAtStopsDayOffset
    def initialize(at_stops)
      @at_stops = at_stops
    end

    def must_be_fixed?(time_of_day, previous_time_of_day)
      return false unless time_of_day && previous_time_of_day

      previous_time_of_day.day_offset == time_of_day.day_offset &&
        previous_time_of_day.hour >= 23 &&
        time_of_day.hour <= 1
    end

    def calculate!
      previous_time_of_day = nil
      @at_stops.each do |vehicle_journey_at_stop|
        %w{arrival departure}.each do |part|
          time_of_day = vehicle_journey_at_stop.send "#{part}_time_of_day"
          if previous_time_of_day && time_of_day
            time_of_day = time_of_day.with_day_offset(previous_time_of_day.day_offset)

            if must_be_fixed?(time_of_day, previous_time_of_day)
              time_of_day = time_of_day.add day_offset: 1
            end

            vehicle_journey_at_stop.send "#{part}_time_of_day=", time_of_day
          end
          previous_time_of_day = time_of_day
        end
      end
    end
  end
end
