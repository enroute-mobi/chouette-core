describe Chouette::VehicleJourneyAtStop do
  describe "#calculate" do

    context 'when departure >= 23 and arrival <= 1' do
      it "increments day offset" do
        at_stops = []
        [
          ['22:30', '22:35'],
          ['23:50', '00:05'],
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

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(0)
        expect(at_stops[1].departure_day_offset).to eq(1)

        expect(at_stops[2].arrival_day_offset).to eq(1)
        expect(at_stops[2].departure_day_offset).to eq(1)
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

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(1)
        expect(at_stops[0].departure_day_offset).to eq(1)

        expect(at_stops[1].arrival_day_offset).to eq(1)
        expect(at_stops[1].departure_day_offset).to eq(1)

        expect(at_stops[2].arrival_day_offset).to eq(1)
        expect(at_stops[2].departure_day_offset).to eq(1)
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

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(1)
        expect(at_stops[1].departure_day_offset).to eq(1)

        expect(at_stops[2].arrival_day_offset).to eq(1)
        expect(at_stops[2].departure_day_offset).to eq(1)

        expect(at_stops[3].arrival_day_offset).to eq(2)
        expect(at_stops[3].departure_day_offset).to eq(2)
      end
    end


    context 'when departure < 23 and arrival <= 1' do
      it "doesn't increments day offset" do
        at_stops = []
        [
          ['22:30', '22:35'],
          ['22:50', '00:05'],
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

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(0)
        expect(at_stops[1].departure_day_offset).to eq(0)

        expect(at_stops[2].arrival_day_offset).to eq(0)
        expect(at_stops[2].departure_day_offset).to eq(0)
      end
    end

    context 'when departure >= 23 and arrival >= 1' do
      it "doesn't increments day offset" do
        at_stops = []
        [
          ['22:30', '22:35'],
          ['22:50', '00:05'],
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

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(0)
        expect(at_stops[1].departure_day_offset).to eq(0)

        expect(at_stops[2].arrival_day_offset).to eq(0)
        expect(at_stops[2].departure_day_offset).to eq(0)
      end
    end
  end
end
