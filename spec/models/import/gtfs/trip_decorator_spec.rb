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
  let(:stop_times) do
    [
      GTFS::StopTime.new(
        trip_id: 'AAMV1',
        stop_id: 'BEATTY_AIRPORT',
        arrival_time: '8:00:00',
        departure_time: '8:00:00',
        stop_sequence: '1'
      ),
      GTFS::StopTime.new(
        trip_id: 'AAMV1',
        stop_id: 'AMV',
        arrival_time: '9:00:00',
        departure_time: '9:00:00',
        stop_sequence: '2'
      )
    ]
  end

  describe '#route_signature' do
    subject { trip_decorator.route_signature }

    context 'without pickup/dropoff' do
      it { is_expected.to eq(['AAMV', '0', []]) }
    end

    context 'with defined pickup/drop_off' do
      before do
        stop_times.first.pickup_type = '1'
        stop_times.second.drop_off_type = '1'
      end

      it { is_expected.to eq(['AAMV', '0', [['AMV', '0', '1', false], ['BEATTY_AIRPORT', '1', '0', false]]]) }

      context 'but not on the last stop' do
        before { stop_times.last.drop_off_type = nil }

        it { is_expected.to eq(['AAMV', '0', [['BEATTY_AIRPORT', '1', '0', false]]]) }
      end

      context 'with location_group_id' do
        before do
          stop_times.first.stop_id = nil
          stop_times.first.location_group_id = 'FLEXIBLE'
        end

        it { is_expected.to eq(['AAMV', '0', [['AMV', '0', '1', false], ['FLEXIBLE', '1', '0', false]]]) }
      end
    end
  end

  describe '#journey_pattern_signature' do
    subject { trip_decorator.journey_pattern_signature }

    it { is_expected.to eq(['AAMV', '0', [], 'to Amargosa Valley', nil, 'BEATTY_AIRPORT', 'AMV']) }

    context 'when stop times is empty' do
      before { trip.stop_times.clear }

      it { is_expected.to be_nil }
    end

    context 'when stop times contains a single Stop Time' do
      before { trip.stop_times = [stop_times.first] }

      it { is_expected.to be_nil }
    end
  end

  describe '#stop_ids' do
    subject { trip_decorator.stop_ids }

    it { is_expected.to eq(%w[BEATTY_AIRPORT AMV]) }
  end

  describe '#journey_pattern' do
    subject { trip_decorator.journey_pattern }

    let(:journey_pattern_found_by_signature) { double('Journey Pattern found by signature') }
    before { trip_decorator.lookup = double(journey_patterns: double) }

    it do
      expect(trip_decorator.lookup.journey_patterns).to receive(:find_by).with(signature: trip_decorator.journey_pattern_signature).and_return(journey_pattern_found_by_signature)
      is_expected.to eq(journey_pattern_found_by_signature)
    end

    context 'when lookup is nil' do
      before { trip_decorator.lookup = nil }

      it { is_expected.to be_nil }
    end

    context 'when journey_pattern_signature is nil' do
      before do
        trip_decorator.lookup = double
        allow(trip_decorator).to receive(:journey_pattern_signature).and_return(nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#chouette_route_id' do
    subject { trip_decorator.chouette_route_id }

    context 'when journey_pattern is associated to the Route 42' do
      before { allow(trip_decorator).to receive(:journey_pattern).and_return(Chouette::JourneyPattern.new(route_id: 42)) }

      it { is_expected.to eq(42) }
    end

    context 'when journey_pattern is not defined' do
      before { allow(trip_decorator).to receive(:journey_pattern).and_return(nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#accessibility_assessment' do
    subject { trip_decorator.accessibility_assessment }

    let(:accessibility_assessment_found) { double('Accessibility Assessment found by wheelchair_accessible') }
    before { trip_decorator.lookup = double(accessibility_assessments: double) }

    it do
      expect(trip_decorator.lookup.accessibility_assessments).to receive(:find_by).with(wheelchair_accessible: trip.wheelchair_accessible).and_return(accessibility_assessment_found)
      is_expected.to eq(accessibility_assessment_found)
    end

    context 'when lookup is nil' do
      before { trip_decorator.lookup = nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#service_facility_set' do
    subject { trip_decorator.service_facility_set }

    let(:service_facility_set_found) { double('ServiceFacilitySet found by bikes_allowed') }
    before { trip_decorator.lookup = double(service_facility_sets: double) }

    it do
      expect(trip_decorator.lookup.service_facility_sets).to receive(:find_by).with(bikes_allowed: trip.bikes_allowed).and_return(service_facility_set_found)
      is_expected.to eq(service_facility_set_found)
    end

    context 'when lookup is nil' do
      before { trip_decorator.lookup = nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#vehicle_journey_at_stops' do
    subject { trip_decorator.vehicle_journey_at_stops }

    context  'when journey_pattern is not defined' do
      before { allow(trip_decorator).to receive(:journey_pattern).and_return(nil) }

      it { is_expected.to be_empty }

      describe 'errors' do
        subject { trip_decorator.errors }
        before { trip_decorator.vehicle_journey_at_stops }

        it { is_expected.to include(an_object_having_attributes(message_key: :journey_pattern_invalid)) }
      end
    end

    context  'when stop_times is empty' do
      before { trip.stop_times.clear }

      it { is_expected.to be_empty }

      describe 'errors' do
        subject { trip_decorator.errors }
        before { trip_decorator.vehicle_journey_at_stops }

        it { is_expected.to include(an_object_having_attributes(message_key: :stop_times_many_required)) }
      end
    end

    context  'when stop_times is empty' do
      before { trip.stop_times.clear }

      it { is_expected.to be_empty }
    end

    context 'when stop times contains a single Stop Time' do
      before { trip.stop_times = [stop_times.first] }

      it { is_expected.to be_empty }
    end

    context 'when JourneyPattern is available' do
      let(:context) do
        Chouette.create do
          route stop_count: 2 do
            journey_pattern
          end
        end
      end

      let(:journey_pattern) { context.journey_pattern }
      before { allow(trip_decorator).to receive(:journey_pattern).and_return(journey_pattern) }

      it { is_expected.to have_attributes(size: 2) }
    end
  end

  describe '#time_table_id' do
    subject { trip_decorator.time_table_id }

    let(:time_table_found) { double('TimeTable found by service_id') }
    before { trip_decorator.lookup = double(time_tables: double) }

    it do
      expect(trip_decorator.lookup.time_tables).to receive(:find_id).with(trip.service_id,
                                                                          starting_day_offset: trip_decorator.starting_day_offset).and_return(time_table_found)
      is_expected.to eq(time_table_found)
    end

    context 'when lookup is nil' do
      before { trip_decorator.lookup = nil }

      it { is_expected.to be_nil }
    end

    context 'when service_id is not defined' do
      before { trip.service_id = nil }

      it { is_expected.to be_nil }
    end

    context 'when lookup is not defined' do
      before { trip_decorator.lookup = nil }

      it { is_expected.to be_nil }
    end

    context 'when lookup is not defined' do
      before { allow(trip_decorator).to receive(:starting_day_offset).and_return(nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#vehicle_journey_time_table_relationships' do
    subject { trip_decorator.vehicle_journey_time_table_relationships }

    context 'when time_table_id is not defined' do
      before { allow(trip_decorator).to receive(:time_table_id).and_return(nil) }

      it { is_expected.to be_empty }

      describe 'errors' do
        subject { trip_decorator.errors }
        before { trip_decorator.vehicle_journey_time_table_relationships }

        it {
          is_expected.to include(an_object_having_attributes(message_key: :service_unknown,
                                                             message_attributes: {
                                                               service_id: trip.service_id, resource_id: trip.id
                                                             }))
        }
      end
    end

    context 'when time_table_id is 42' do
      before { allow(trip_decorator).to receive(:time_table_id).and_return(42) }

      it { is_expected.to contain_exactly(an_object_having_attributes(time_table_id: 42)) }
      it { is_expected.to contain_exactly(an_instance_of(Chouette::TimeTablesVehicleJourney)) }
    end
  end

  describe '#code' do
    subject { trip_decorator.code }

    context 'when code_space is "test"' do
      before { trip_decorator.code_space = CodeSpace.new(short_name: 'test') }

      it { is_expected.to have_attributes(code_space: an_object_having_attributes(short_name: 'test')) }
      it { is_expected.to have_attributes(value: trip.id) }
    end

    context 'when code_space is not defined' do
      before { trip_decorator.code_space = nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#published_journey_name' do
    subject { trip_decorator.published_journey_name }

    context 'when Trip short_name is "dummy"' do
      before { trip.short_name = 'dummy' }

      it { is_expected.to be(trip.short_name) }
    end

    context 'when Trip short_name is undefined and Trip id "AAMV1"' do
      before { trip.short_name = nil }

      it { is_expected.to be(trip.id) }
    end
  end

  describe '#published_journey_identifier' do
    subject { trip_decorator.published_journey_identifier }

    context 'when Trip id "AAMV1"' do
      it { is_expected.to be(trip.id) }
    end
  end

  describe '#starting_day_offset' do
    subject { trip_decorator.starting_day_offset }

    context 'when no stop_times is defined' do
      before { trip.stop_times.clear }

      it { is_expected.to be_zero }
    end

    context 'when first stop_time departure time is 12:00:00' do
      before { trip.stop_times.first.departure_time = '12:00:00' }

      it { is_expected.to be_zero }
    end

    context 'when first stop_time departure time is 24:00:00' do
      before { trip.stop_times.first.departure_time = '24:00:00' }

      it { is_expected.to eq(1) }
    end

    context 'when first stop_time departure time is 48:00:00' do
      before { trip.stop_times.first.departure_time = '48:00:00' }

      it { is_expected.to eq(2) }
    end

    context 'when first stop_time departure time is "dummy"' do
      before { trip.stop_times.first.departure_time = 'dummy' }

      it { is_expected.to be_zero }
    end
  end
end
