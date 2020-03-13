
describe Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator do
  subject { create(:vehicle_journey_odd) }

  describe "#validate" do
    before(:each) do
      subject.vehicle_journey_at_stops[0].departure_time =
        subject.vehicle_journey_at_stops[1].departure_time - 5.hour
      subject.vehicle_journey_at_stops[0].arrival_time =
        subject.vehicle_journey_at_stops[0].departure_time
      subject.vehicle_journey_at_stops[1].arrival_time =
        subject.vehicle_journey_at_stops[1].departure_time
    end

    it "should make instance invalid if departure time exceeds gap", :skip => "Time gap validation is in pending status" do
      subject.validate

      expect(
        subject.vehicle_journey_at_stops[1].errors[:departure_time]
      ).not_to be_blank
      expect(subject).not_to be_valid
    end
  end

  describe ".validate_at_stop_times_must_increase" do
    let!(:vehicle_journey) { create(:vehicle_journey_odd) }
    subject { vehicle_journey.vehicle_journey_at_stops.first }

    let(:vjas1) { vehicle_journey.vehicle_journey_at_stops[0] }
    let(:vjas2) { vehicle_journey.vehicle_journey_at_stops[1] }

    context "when vjas#arrival_time exceeds gap" do
      it "should add errors on arrival_time", :skip => "Time gap validation is in pending status" do
        vjas1.arrival_time = vjas2.arrival_time - 5.hour
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .validate_at_stop_times_must_increase(vjas2, vjas1)
        ).to be_falsey
        expect(vjas2.errors).not_to be_empty
        expect(vjas2.errors[:arrival_time]).not_to be_blank
      end
    end

    context "when vjas#departure_time exceeds gap" do
      it "should add errors on departure_time", :skip => "Time gap validation is in pending status" do
        vjas1.departure_time = vjas2.departure_time - 5.hour
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .validate_at_stop_times_must_increase(vjas2, vjas1)
        ).to be_falsey
        expect(vjas2.errors).not_to be_empty
        expect(vjas2.errors[:departure_time]).not_to be_blank
      end
    end

    context "when vjas doesn't exceed gap" do
      it "should not add errors", :skip => "Time gap validation is in pending status" do
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .validate_at_stop_times_must_increase(vjas2, vjas1)
        ).to be_truthy
        expect(vjas2.errors).to be_empty
      end
    end
  end
end
