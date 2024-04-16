describe Chouette::VehicleJourneyAtStopsDayOffset do
  describe "#calculate" do

    context 'when vehicle journey at stops departure and arrival >= 23  <= 1' do
      it "increments day offset" do
        at_stops = []
        [
          ['23:30', '23:50'],
          ['00:05', '00:15'],
          ['00:30', '00:35']
        ].each do |arrival_time, departure_time|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: 0,
            departure_day_offset: 0
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and change(at_stops[1], :arrival_day_offset).by(1)
          .and change(at_stops[1], :departure_day_offset).by(1)
          .and change(at_stops[2], :arrival_day_offset).by(1)
          .and change(at_stops[2], :departure_day_offset).by(1)
      end

      it 'return offset 1 if the first time of day has offset 1' do
        at_stops = []
        [
          ['00:00', '00:00', 1],
          ['00:05', '00:05', 1],
          ['00:10', '00:10', 1]
        ].each do |arrival_time, departure_time, day_offset|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: day_offset,
            departure_day_offset: day_offset
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and not_change(at_stops[1], :arrival_day_offset)
          .and not_change(at_stops[1], :departure_day_offset)
          .and not_change(at_stops[2], :arrival_day_offset)
          .and not_change(at_stops[2], :departure_day_offset)
      end

      it "increments day offset for multi-day offsets" do
        at_stops = []
        [
          ['23:30', '23:35'],
          ['00:02', '00:14'],
          ['23:30', '23:35'],
          ['00:02', '00:04'],
        ].each do |arrival_time, departure_time|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and change(at_stops[1], :arrival_day_offset).by(1)
          .and change(at_stops[1], :departure_day_offset).by(1)
          .and change(at_stops[2], :arrival_day_offset).by(1)
          .and change(at_stops[2], :departure_day_offset).by(1)
          .and change(at_stops[3], :arrival_day_offset).by(2)
          .and change(at_stops[3], :departure_day_offset).by(2)
      end

      it "increments day offset even when a time zone is present" do
        at_stops = []
        [
          ['23:30', '23:50'],
          ['00:05', '00:15'],
          ['00:30', '00:35']
        ].each do |arrival_time, departure_time|
          at_stops << Chouette::VehicleJourneyAtStop.new.tap do |vehicle_journey_at_stop|
            vehicle_journey_at_stop.arrival_time_of_day = TimeOfDay.parse(arrival_time, utc_offset: 3600)
            vehicle_journey_at_stop.departure_time_of_day = TimeOfDay.parse(departure_time, utc_offset: 3600)
          end.tap do |vehicle_journey_at_stop|
            # Simulate a StopArea time zone
            allow(vehicle_journey_at_stop).to receive(:time_zone_offset).and_return(3600)
          end
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and change(at_stops[1], :arrival_day_offset).by(1)
          .and change(at_stops[1], :departure_day_offset).by(1)
          .and change(at_stops[2], :arrival_day_offset).by(1)
          .and change(at_stops[2], :departure_day_offset).by(1)
      end
    end

    context 'when first vehicle journey at stops departure and arrival < 23 and second vehicle journey at stops departure and arrival <= 1' do
      it "doesn't increments day offset" do
        at_stops = []
        [
          ['22:50', '22:50', 0, 0],
          ['00:05', '00:05', 1, 1],
        ].each do |arrival_time, departure_time, arrival_day_offset, departure_day_offset|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: arrival_day_offset,
            departure_day_offset: departure_day_offset
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and not_change(at_stops[1], :arrival_day_offset)
          .and not_change(at_stops[1], :departure_day_offset)
      end
    end

    context 'when vehicle journey at stops departure and arrival < 23' do
      it "doesn't increments day offset" do
        at_stops = []
        [
          ['22:30', '22:30'],
          ['22:50', '22:50'],
        ].each do |arrival_time, departure_time|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: 0,
            departure_day_offset: 0
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and not_change(at_stops[1], :arrival_day_offset)
          .and not_change(at_stops[1], :departure_day_offset)
      end
    end

    context 'when vehicle journey at stops departure and arrival > 1' do
      it "doesn't increments day offset" do
        at_stops = []
        [
          ['01:15', '01:15'],
          ['01:30', '01:35']
        ].each do |arrival_time, departure_time|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: 0,
            departure_day_offset: 0
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        expect{ offsetter.calculate! }.to not_change(at_stops[0], :arrival_day_offset)
          .and not_change(at_stops[0], :departure_day_offset)
          .and not_change(at_stops[1], :arrival_day_offset)
          .and not_change(at_stops[1], :departure_day_offset)
      end
    end
  end
end
