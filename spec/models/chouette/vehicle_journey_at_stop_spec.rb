
RSpec.describe Chouette::VehicleJourneyAtStop, type: :model do
  subject { build_stubbed(:vehicle_journey_at_stop) }

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

  context 'when updated in a ChecksumManager transaction' do
    it 'should compute checksum right' do
      vjas = nil
      vj = create(:vehicle_journey)
      Chouette::ChecksumManager.transaction do
        vjas = create(:vehicle_journey_at_stop, arrival_time: '07:00', departure_time: '08:00', vehicle_journey: vj)
        vjas = Chouette::VehicleJourneyAtStop.find vjas.id
        vjas.update departure_time: '10:00'
      end
      expect { vjas.reload.set_current_checksum_source }.to_not change { vjas.checksum_source }
      expect(vjas.current_checksum_source).to eq '10:00|07:00|0|0'
    end
  end

  describe "#day_offset_outside_range?" do
    let (:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

    it "disallows negative offsets" do
      expect(at_stop.day_offset_outside_range?(-1)).to be true
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

  describe "#validate" do
    it "displays the proper error message when day offset exceeds the max" do
      bad_offset = Chouette::VehicleJourneyAtStop.day_offset_max + 1

      at_stop = build_stubbed(
        :vehicle_journey_at_stop,
        arrival_day_offset: bad_offset,
        departure_day_offset: bad_offset
      )
      error_message = I18n.t(
        'vehicle_journey_at_stops.errors.day_offset_must_not_exceed_max',
        short_id: at_stop.vehicle_journey.get_objectid.short_id,
        max: bad_offset
      )

      at_stop.validate

      expect(at_stop.errors[:arrival_day_offset]).to include(error_message)
      expect(at_stop.errors[:departure_day_offset]).to include(error_message)
    end
  end
end
