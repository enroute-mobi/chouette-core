RSpec.describe Chouette::VehicleJourneyAtStop, type: :model do
  subject(:vehicle_journey_at_stop) { described_class.new }

  it { is_expected.to_not validate_presence_of(:earliest_departure_time_of_day) }

  describe '#earliest_departure_time_of_day' do
    subject { vehicle_journey_at_stop.earliest_departure_time_of_day }

    context 'when raw value is nil' do
      it { is_expected.to be_nil }
    end
  end

  describe '#earliest_departure_local_time_of_day' do
    subject { vehicle_journey_at_stop.earliest_departure_local_time_of_day }

    context 'when earliest_departure_time_of_day is nil' do
      it { is_expected.to be_nil }
    end

    context 'when earliest_departure_time_of_day is 00:00' do
      before { vehicle_journey_at_stop.earliest_departure_time_of_day = TimeOfDay.parse('00:00') }

      context 'when time_zone is "Europe/London"' do
        before { vehicle_journey_at_stop.raw_time_zone = 'Europe/London' }

        it { is_expected.to eq(TimeOfDay.parse('00:00')) }
      end

      context 'when time_zone is "Europe/Paris"' do
        before { vehicle_journey_at_stop.raw_time_zone = 'Europe/Paris' }

        it { is_expected.to eq(TimeOfDay.parse('00:00', time_zone: 'Europe/Paris')) }
      end
    end
  end

  describe '#latest_arrival_local_time_of_day' do
    subject { vehicle_journey_at_stop.latest_arrival_local_time_of_day }

    context 'when latest_arrival_time_of_day is nil' do
      it { is_expected.to be_nil }
    end

    context 'when latest_arrival_time_of_day is 00:00' do
      before { vehicle_journey_at_stop.latest_arrival_time_of_day = TimeOfDay.parse('00:00') }

      context 'when time_zone is "Europe/London"' do
        before { vehicle_journey_at_stop.raw_time_zone = 'Europe/London' }

        it { is_expected.to eq(TimeOfDay.parse('00:00')) }
      end

      context 'when time_zone is "Europe/Paris"' do
        before { vehicle_journey_at_stop.raw_time_zone = 'Europe/Paris' }

        it { is_expected.to eq(TimeOfDay.parse('00:00', time_zone: 'Europe/Paris')) }
      end
    end
  end

  describe 'checksum' do
    subject(:at_stop) { create(:vehicle_journey_at_stop) }

    it_behaves_like 'checksum support'

    context '#checksum_attributes' do
      it 'should return attributes' do
        expected = [at_stop.departure_time.utc.to_s(:time), at_stop.arrival_time.utc.to_s(:time)]
        expected << at_stop.departure_day_offset.to_s
        expected << at_stop.arrival_day_offset.to_s
        expect(at_stop.checksum_attributes).to include(*expected)
      end
    end
  end

  context 'time allocation' do
    it 'should work correctly' do
      vjas = Chouette::VehicleJourneyAtStop.new
      vjas.arrival_time = '12:00'
      expect(vjas.arrival_time.to_s).to eq "2000-01-01 12:00:00 UTC"
      vjas.arrival_time = "2000-01-01 12:00:00 UTC"
      expect(vjas.arrival_time.to_s).to eq "2000-01-01 12:00:00 UTC"
      vjas.arrival_time = "2000-01-01 12:00:00 UTC".to_time
      expect(vjas.arrival_time.to_s).to eq "2000-01-01 12:00:00 UTC"

      vjas.arrival_time = 'Sun, 01 Jan 2000 00:10:00 CET +01:00'.to_time
      expect(vjas.arrival_time.to_s).to eq "2000-01-01 23:10:00 UTC"
      vjas.arrival_time = 'Sun, 02 Jan 2000 00:10:00 CET +01:00'.to_time
      expect(vjas.arrival_time.to_s).to eq "2000-01-01 23:10:00 UTC"
    end
  end

  describe "#day_offset_outside_range?" do
    let(:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

    it "allows offset at -1" do
      expect(at_stop.day_offset_outside_range?(-1)).to be false
    end

    it "disallows offsets greater than DAY_OFFSET_MAX" do
      expect(at_stop.day_offset_outside_range?(
        Chouette::VehicleJourneyAtStop.day_offset_max + 1
      )).to be true
    end

    it "allows offsets between 0 and DAY_OFFSET_MAX inclusive" do
      expect(at_stop.day_offset_outside_range?(
        Chouette::VehicleJourneyAtStop.day_offset_max
      )).to be false
    end

    it "forces a nil offset to 0" do
      expect(at_stop.day_offset_outside_range?(nil)).to be false
    end

    it "allows any value when max isn't defined" do
      allow(at_stop).to receive(:day_offset_max).and_return(nil)
      expect(at_stop.day_offset_outside_range?(1024)).to be false
    end
  end

  context "the different times" do
    let (:at_stop) { create(:vehicle_journey_at_stop) }

    describe "without a TimeZone" do
      it "should not offset times" do
        expect(at_stop.departure).to eq at_stop.departure_local
        expect(at_stop.arrival).to eq at_stop.arrival_local
      end
    end

    describe "with a TimeZone" do
      let(:stop){ at_stop.stop_point.stop_area }
      before(:each) do
        stop.update time_zone: 'America/Mexico_City'
      end

      it "should offset times" do
        expect(at_stop.departure_local).to eq at_stop.send(:format_time, at_stop.departure_time - 6.hours)
        expect(at_stop.arrival_local).to eq at_stop.send(:format_time, at_stop.arrival_time - 6.hours)
      end

      it "should not be sensible to winter/summer time" do
        stop.update time_zone: 'Europe/Paris'
        summer_time = Timecop.freeze("2000/08/01 12:00:00".to_time) { at_stop.departure_local }
        winter_time = Timecop.freeze("2000/12/01 12:00:00".to_time) { at_stop.departure_local }
        expect(summer_time).to eq winter_time
      end

      it 'should convert time to UTC vals' do
        at_stop.arrival_local_time = '12:00'
        at_stop.departure_local_time = '23:00'

        expect(at_stop.send(:format_time, at_stop.arrival_time)).to eq '18:00'
        expect(at_stop.send(:format_time, at_stop.departure_time)).to eq '05:00'
      end
    end
  end

  describe 'validation' do
    it 'does not crash when arrival_time, departure_time, earliest_departure_time_of_day and latest_arrival_time_of_day are all nil' do # rubocop:disable Layout/LineLength
      expect { vehicle_journey_at_stop.valid? }.not_to raise_error
    end

    describe '#arrival_must_be_before_departure' do
      it 'is valid when arrival_time is before departure_time' do
        vehicle_journey_at_stop.arrival_time_of_day = TimeOfDay.new(8, 0)
        vehicle_journey_at_stop.departure_time_of_day = TimeOfDay.new(9, 0)
        expect { vehicle_journey_at_stop.valid? }.not_to(
          change { vehicle_journey_at_stop.errors[:arrival_time] }.from(be_empty)
        )
      end

      it 'is not valid when arrival_time is after departure_time' do
        vehicle_journey_at_stop.arrival_time_of_day = TimeOfDay.new(9, 0)
        vehicle_journey_at_stop.departure_time_of_day = TimeOfDay.new(8, 0)
        expect { vehicle_journey_at_stop.valid? }.to(
          change { vehicle_journey_at_stop.errors[:arrival_time] }.from(be_empty).to(be_present)
        )
      end
    end

    describe '#earliest_departure_time_of_day_must_be_before_latest_arrival_time_of_day' do
      it 'is valid when earliest_departure_time_of_day is before latest_arrival_time_of_day' do
        vehicle_journey_at_stop.latest_arrival_time_of_day = TimeOfDay.new(9, 0)
        expect(vehicle_journey_at_stop).to allow_value(TimeOfDay.new(8, 0)).for(:earliest_departure_time_of_day)
      end

      it 'is not valid when arrival time is after latest_arrival_time_of_day' do
        vehicle_journey_at_stop.latest_arrival_time_of_day = TimeOfDay.new(8, 0)
        expect(vehicle_journey_at_stop).not_to allow_value(TimeOfDay.new(9, 0)).for(:earliest_departure_time_of_day)
      end
    end

    it "displays the proper error message when day offset exceeds the max" do
      bad_offset = Chouette::VehicleJourneyAtStop.day_offset_max + 1

      at_stop = build_stubbed(
        :vehicle_journey_at_stop,
        arrival_day_offset: bad_offset,
        departure_day_offset: bad_offset
      )
      error_message = I18n.t(
        'activerecord.errors.models.vehicle_journey_at_stop.day_offset_must_not_exceed_max',
        short_id: at_stop.vehicle_journey.get_objectid.short_id,
        max: Chouette::VehicleJourneyAtStop.day_offset_max
      )

      at_stop.validate

      expect(at_stop.errors[:arrival_day_offset]).to include(error_message)
      expect(at_stop.errors[:departure_day_offset]).to include(error_message)
    end
  end

  describe "#find_each_light" do

    let(:context) do
      Chouette.create { vehicle_journey }
    end

    before { context.referential.switch }

    let(:vehicle_journey_at_stops) { referential.vehicle_journey_at_stops }
    let(:light_vehicle_journey_at_stops) { referential.vehicle_journey_at_stops.enum_for(:find_each_light) }

    it "should return the same identifiers" do
      expect(light_vehicle_journey_at_stops.map(&:id)).to match_array(vehicle_journey_at_stops.pluck(:id))
    end

    it "have the same attributes than the same 'classic' VehicleJourneyAtStop" do
      attributes = [ :vehicle_journey_id, :stop_point_id, :stop_area_id,
                     :checksum, :checksum_source, :departure_day_offset, :arrival_day_offset ]
      same_vehicle_journey_at_stop = ->(light) { vehicle_journey_at_stops.find(light.id) }
      expect(light_vehicle_journey_at_stops).to all(have_same_attributes(attributes, than: same_vehicle_journey_at_stop))
    end

    it "have the same departure time than the same 'classic' VehicleJourneyAtStop" do
      have_same_departure_time = satisfy("have the same departure time") do |light|
        vehicle_journey_at_stops.find(light.id).departure_time.strftime("%H:%M:%S") == light.departure_time
      end

      expect(light_vehicle_journey_at_stops).to all(have_same_departure_time)
    end

    it "have the same arrival time than the same 'classic' VehicleJourneyAtStop" do
      have_same_arrival_time = satisfy("have the same arrival time") do |light|
        vehicle_journey_at_stops.find(light.id).arrival_time.strftime("%H:%M:%S") == light.arrival_time
      end

      expect(light_vehicle_journey_at_stops).to all(have_same_arrival_time)
    end

  end

end
