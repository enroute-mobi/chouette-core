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

          if previous_time_of_day.present? && time_of_day < previous_time_of_day
            time_of_day = time_of_day.add day_offset: 1
            vehicle_journey_at_stop.send "#{part}_time_of_day=", time_of_day
          end

          previous_time_of_day = time_of_day
        end
      end
    end

    # def calculate!(force_reset=false)
    #   return if @at_stops.empty?
    #   offset = @at_stops.first.departure_day_offset
    #   @at_stops.select{|s| s.arrival_time.present? && s.departure_time.present? }.inject(nil) do |prior_stop, stop|
    #     if prior_stop.nil?
    #       stop.departure_day_offset = offset
    #       stop.arrival_day_offset = offset
    #       next stop
    #     end

    #     stop_arrival_time = stop.arrival_time_with_zone
    #     prior_stop_departure_time = prior_stop.departure_time_with_zone

    #     # Compare Time with Zone 23:00 +001 with 00:05 +002
    #     if stop_arrival_time < prior_stop_departure_time
    #       offset += 1
    #     end

    #     unless force_reset
    #       offset = [stop.arrival_day_offset, offset].max
    #     end

    #     stop.arrival_day_offset = offset

    #     # Compare '23:00' with '00:05' for example
    #     if stop.departure_local < stop.arrival_local
    #       offset += 1
    #     end

    #     unless force_reset
    #       offset = [stop.departure_day_offset, offset].max
    #     end
    #     stop.departure_day_offset = offset

    #     stop
    #   end
    # end

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
