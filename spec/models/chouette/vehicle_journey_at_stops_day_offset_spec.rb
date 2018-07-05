require 'spec_helper'

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
          arrival_day_offset: 12,
          departure_day_offset: 12
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

    context "with stops in a different timezone" do
      before do
        allow_any_instance_of(Chouette::VehicleJourneyAtStop).to receive(:local_time).and_wrap_original {|m, t| m.call(t - 12.hours)}
      end

      it "should apply the TZ" do
        at_stops = []
        [
          ['22:30', '22:35'],
          ['01:02', '01:14'],
          ['12:02', '12:14'],
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

        expect(at_stops[1].arrival_day_offset).to eq(0)
        expect(at_stops[1].departure_day_offset).to eq(0)

        expect(at_stops[2].arrival_day_offset).to eq(1)
        expect(at_stops[2].departure_day_offset).to eq(1)
      end
    end

    context "with stops in different timezones" do

      it "should apply the TZ" do
        at_stops = []

        stop_area = create(:stop_area, time_zone: "Paris")
        stop_point = create(:stop_point, stop_area: stop_area)
        vehicle_journey_at_stop = build_stubbed(
          :vehicle_journey_at_stop,
          stop_point: stop_point,
          arrival_time: '23:00',
          departure_time: '23:55'
        )

        at_stops << vehicle_journey_at_stop

        stop_area = create(:stop_area, time_zone: "Portugal")
        stop_point = create(:stop_point, stop_area: stop_area)
        vehicle_journey_at_stop = build_stubbed(
          :vehicle_journey_at_stop,
          stop_point: stop_point,
          arrival_time: '23:05',
          departure_time: '23:10'
        )
        at_stops << vehicle_journey_at_stop

        vehicle_journey_at_stop = build_stubbed(
          :vehicle_journey_at_stop,
          stop_point: stop_point,
          arrival_time: '00:05',
          departure_time: '00:10'
        )
        at_stops << vehicle_journey_at_stop


        offsetter = Chouette::VehicleJourneyAtStopsDayOffset.new(at_stops)

        offsetter.calculate!

        expect(at_stops[0].arrival_day_offset).to eq(0)
        expect(at_stops[0].departure_day_offset).to eq(0)

        expect(at_stops[1].arrival_day_offset).to eq(0)
        expect(at_stops[1].departure_day_offset).to eq(0)

        expect(at_stops[2].arrival_day_offset).to eq(1)
        expect(at_stops[2].departure_day_offset).to eq(1)
      end
    end
  end
end
