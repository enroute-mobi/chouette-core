module Chouette
  class VehicleJourneyAtStopsDayOffset
    def initialize(at_stops)
      @at_stops = at_stops
    end

    def calculate!
      previous_time_of_day = nil
      @at_stops.each do |vehicle_journey_at_stop|
        %w{arrival departure}.each do |part|
          time_of_day = vehicle_journey_at_stop.send "#{part}_time_of_day"
          next if time_of_day.nil?

          if previous_time_of_day.present?
            if time_of_day < previous_time_of_day
              # First, we change the time_of_day to be on the same "day"
              time_of_day = time_of_day.with_day_offset previous_time_of_day.day_offset

              if time_of_day < previous_time_of_day
                # If needed, we're adding a "day"
                time_of_day = time_of_day.add day_offset: 1
              end

              vehicle_journey_at_stop.send "#{part}_time_of_day=", time_of_day
            end

          end

          previous_time_of_day = time_of_day
        end
      end
    end

    def save
      @at_stops.each do |at_stop|
        attrs = %i[departure_day_offset arrival_day_offset]
        at_stop.save if attrs.any? { |attr| at_stop.send("#{attr}_changed?")}
      end
    end

    def update
      calculate!
      save
    end
  end
end
