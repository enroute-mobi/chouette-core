# frozen_string_literal: true

RSpec.describe Import::Gtfs::TripDecorator do
  subject(:trip_decorator) { described_class.new(trip) }

  let(:trip) do
    GTFS::Trip.new(
      id: 'AAMV1',
      route_id: 'AAMV',
      service_id: 'WE',
      direction_id: '0',
      headsign: 'to Amargosa Valley',
      stop_times: stop_times
    )
  end
  let(:stop_time_1_pickup) { nil }
  let(:stop_time_1_drop_off) { nil }
  let(:stop_time_2_pickup) { nil }
  let(:stop_time_2_drop_off) { nil }
  let(:stop_times) do
    [
      GTFS::StopTime.new(
        trip_id: 'AAMV1',
        stop_id: 'BEATTY_AIRPORT',
        arrival_time: '8:00:00',
        departure_time: '8:00:00',
        stop_sequence: '1',
        pickup_type: stop_time_1_pickup,
        drop_off_type: stop_time_1_drop_off
      ),
      GTFS::StopTime.new(
        trip_id: 'AAMV1',
        stop_id: 'AMV',
        arrival_time: '9:00:00',
        departure_time: '9:00:00',
        stop_sequence: '2',
        pickup_type: stop_time_2_pickup,
        drop_off_type: stop_time_2_drop_off
      )
    ]
  end

  describe '#route_signature' do
    subject { trip_decorator.route_signature }

    context 'without pickup/dropoff' do
      it { is_expected.to eq(['AAMV', '0', []]) }
    end

    context 'with pickup/drop_off' do
      let(:stop_time_1_pickup) { '1' }
      let(:stop_time_2_drop_off) { '1' }

      it { is_expected.to eq(['AAMV', '0', [['AMV', '0', '1', false], ['BEATTY_AIRPORT', '1', '0', false]]]) }

      context 'but not on the last stop' do
        let(:stop_time_2_drop_off) { nil }

        it { is_expected.to eq(['AAMV', '0', [['BEATTY_AIRPORT', '1', '0', false]]]) }
      end

      context 'with location_group_id' do
        let(:stop_times) do
          [
            GTFS::StopTime.new(
              trip_id: 'AAMV1',
              stop_id: nil,
              location_group_id: 'FLEXIBLE',
              arrival_time: '8:00:00',
              departure_time: '8:00:00',
              stop_sequence: '1',
              pickup_type: stop_time_1_pickup,
              drop_off_type: stop_time_1_drop_off
            ),
            GTFS::StopTime.new(
              trip_id: 'AAMV1',
              stop_id: 'AMV',
              arrival_time: '9:00:00',
              departure_time: '9:00:00',
              stop_sequence: '2',
              pickup_type: stop_time_2_pickup,
              drop_off_type: stop_time_2_drop_off
            )
          ]
        end

        it { is_expected.to eq(['AAMV', '0', [['AMV', '0', '1', false], ['FLEXIBLE', '1', '0', false]]]) }
      end
    end
  end

  describe '#journey_pattern_signature' do
    subject { trip_decorator.journey_pattern_signature }

    it { is_expected.to eq(['AAMV', '0', [], 'to Amargosa Valley', nil, 'BEATTY_AIRPORT', 'AMV']) }
  end
end
