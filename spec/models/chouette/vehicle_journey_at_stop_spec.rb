RSpec.describe Chouette::VehicleJourneyAtStop, type: :model do
  describe 'checksum' do
    let(:at_stop) { build_stubbed(:vehicle_journey_at_stop) }

    context '#checksum_attributes' do
      it 'should return attributes' do
        expected = [at_stop.departure_time.to_s(:time), at_stop.arrival_time.to_s(:time)]
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
        local_id: at_stop.vehicle_journey.objectid.local_id,
        max: bad_offset
      )

      at_stop.validate

      expect(at_stop.errors[:arrival_day_offset]).to include(error_message)
      expect(at_stop.errors[:departure_day_offset]).to include(error_message)
    end
  end
end
