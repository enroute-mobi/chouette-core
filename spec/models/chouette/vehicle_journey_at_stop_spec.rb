require 'spec_helper'

RSpec.describe Chouette::VehicleJourneyAtStop, type: :model do
  subject { create(:vehicle_journey_at_stop) }

  describe 'checksum' do
    let(:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

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

  describe "#day_offset_outside_range?" do
    let (:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

    it "disallows negative offsets" do
      expect(at_stop.day_offset_outside_range?(-1)).to be true
    end

    it "disallows offsets greater than DAY_OFFSET_MAX" do
      expect(at_stop.day_offset_outside_range?(
        Chouette::VehicleJourneyAtStop::DAY_OFFSET_MAX + 1
      )).to be true
    end

    it "allows offsets between 0 and DAY_OFFSET_MAX inclusive" do
      expect(at_stop.day_offset_outside_range?(
        Chouette::VehicleJourneyAtStop::DAY_OFFSET_MAX
      )).to be false
    end

    it "forces a nil offset to 0" do
      expect(at_stop.day_offset_outside_range?(nil)).to be false
    end
  end

  context "the different times" do
    let (:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

    describe "without a TimeZone" do
      it "should not offset times" do
        expect(at_stop.departure).to eq at_stop.departure_local
        expect(at_stop.arrival).to eq at_stop.arrival_local
      end
    end


    describe "with a TimeZone" do
      before(:each) do
        stop = at_stop.stop_point.stop_area
        stop.time_zone = "Mexico City"
      end

      it "should offset times" do
        expect(at_stop.departure_local).to eq at_stop.send(:format_time, at_stop.departure_time - 6.hours)
        expect(at_stop.arrival_local).to eq at_stop.send(:format_time, at_stop.arrival_time - 6.hours)
      end

      context "with a wrong Timezone" do
        before do
          at_stop.stop_point.stop_area.time_zone = "Gotham City"
        end

        it "should not offset times" do
          expect(at_stop.departure_local).to eq at_stop.send(:format_time, at_stop.departure_time)
          expect(at_stop.arrival_local).to eq at_stop.send(:format_time, at_stop.arrival_time)
        end
      end
    end
  end

  describe "#validate" do
    it "displays the proper error message when day offset exceeds the max" do
      bad_offset = Chouette::VehicleJourneyAtStop::DAY_OFFSET_MAX + 1

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
