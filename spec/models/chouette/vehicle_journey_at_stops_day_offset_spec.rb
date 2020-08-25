describe Chouette::VehicleJourneyAtStop do
  describe "#calculate" do
    it "increments day offset when departure & arrival are on different sides
        of midnight" do
      at_stops = []
      [
        ['22:30', '22:35'],
        ['23:50', '00:05'],
        ['00:30', '00:35'],
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

    it 'keeps increments when full days are skipped' do
      at_stops = []
      [
        ['22:30', '22:35', 0],
        ['23:50', '00:05', 12],
        ['00:30', '00:35', 12],
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

      expect(at_stops[0].arrival_day_offset).to eq(0)
      expect(at_stops[0].departure_day_offset).to eq(0)

      expect(at_stops[1].arrival_day_offset).to eq(12)
      expect(at_stops[1].departure_day_offset).to eq(13)

      expect(at_stops[2].arrival_day_offset).to eq(13)
      expect(at_stops[2].departure_day_offset).to eq(13)
    end

    it 'return the correct offset if the first day have offset 1' do
      at_stops = []
      [
        ['00:00', '00:00', 1],
        ['00:05', '00:05', 1],
        ['00:10', '00:10', 1],
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

    it "increments day offset when an at_stop passes midnight the next day" do
      at_stops = []
      [
        ['22:30', '22:35'],
        ['01:02', '01:14'],
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
    end

    it "increments day offset for multi-day offsets" do
      at_stops = []
      [
        ['22:30', '22:35'],
        ['01:02', '01:14'],
        ['04:30', '04:35'],
        ['00:00', '00:04'],
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

    context 'with offsets already set' do
      it "keeps the offsets" do
        at_stops = []
        [
          ['22:30', '22:35', 0],
          ['01:02', '01:14', 1],
          ['04:30', '04:35', 2],
          ['00:00', '00:04', 3],
        ].each do |arrival_time, departure_time, offset|
          at_stops << build_stubbed(
            :vehicle_journey_at_stop,
            arrival_time: arrival_time,
            departure_time: departure_time,
            arrival_day_offset: offset,
            departure_day_offset: offset
          )
        end

        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(1)
        expect(at_stops[1].departure_day_offset).to eq(1)

        expect(at_stops[2].arrival_day_offset).to eq(2)
        expect(at_stops[2].departure_day_offset).to eq(2)

        expect(at_stops[3].arrival_day_offset).to eq(3)
        expect(at_stops[3].departure_day_offset).to eq(3)
      end
    end
  end

  context 'when the day offset changes from 0 to -1' do

    it "restore correct offsets" do
      at_stops = []
      [
        ['22:30', '22:35', 0],
        ['08:00', '08:05', 0],
        ['23:30', '23:35', -1],
      ].each do |arrival_time, departure_time, offset|
        at_stops << build_stubbed(
          :vehicle_journey_at_stop,
          arrival_time: arrival_time,
          departure_time: departure_time,
          arrival_day_offset: offset,
          departure_day_offset: offset
        )
      end

      Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops).calculate!

      expect(at_stops.map(&:arrival_day_offset)).to eq([0,1,1])
    end

  end

end
