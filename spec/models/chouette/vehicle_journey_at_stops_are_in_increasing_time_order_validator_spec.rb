require 'spec_helper'

describe Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator do
  subject { create(:vehicle_journey_odd) }

  describe "#increasing_times" do
    before(:each) do
      subject.vehicle_journey_at_stops[0].departure_time =
        subject.vehicle_journey_at_stops[1].departure_time - 5.hour
      subject.vehicle_journey_at_stops[0].arrival_time =
        subject.vehicle_journey_at_stops[0].departure_time
      subject.vehicle_journey_at_stops[1].arrival_time =
        subject.vehicle_journey_at_stops[1].departure_time
    end

    it "should make instance invalid" do
      subject.validate

      expect(
        subject.vehicle_journey_at_stops[1].errors[:departure_time]
      ).not_to be_blank
      expect(subject).not_to be_valid
    end
  end

  # TODO: Move to TimeDuration
  # describe "#exceeds_gap?" do
  #   let!(:vehicle_journey) { create(:vehicle_journey_odd) }
  #   subject { vehicle_journey.vehicle_journey_at_stops.first }
  #
  #   it "should return false if gap < 1.hour" do
  #     t1 = Time.now
  #     t2 = Time.now + 3.minutes
  #     expect(subject.exceeds_gap?(t1, t2)).to be_falsey
  #   end
  #
  #   it "should return true if gap > 4.hour" do
  #     t1 = Time.now
  #     t2 = Time.now + (4.hours + 1.minutes)
  #     expect(subject.exceeds_gap?(t1, t2)).to be_truthy
  #   end
  # end

  describe ".increasing_times_validate" do
    let!(:vehicle_journey) { create(:vehicle_journey_odd) }
    subject { vehicle_journey.vehicle_journey_at_stops.first }

    let(:vjas1) { vehicle_journey.vehicle_journey_at_stops[0] }
    let(:vjas2) { vehicle_journey.vehicle_journey_at_stops[1] }

    context "when vjas#arrival_time exceeds gap" do
      it "should add errors on arrival_time" do
        vjas1.arrival_time = vjas2.arrival_time - 5.hour
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .increasing_times_validate(vjas2, vjas1)
        ).to be_falsey
        expect(vjas2.errors).not_to be_empty
        expect(vjas2.errors[:arrival_time]).not_to be_blank
      end
    end

    context "when vjas#departure_time exceeds gap" do
      it "should add errors on departure_time" do
        vjas1.departure_time = vjas2.departure_time - 5.hour
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .increasing_times_validate(vjas2, vjas1)
        ).to be_falsey
        expect(vjas2.errors).not_to be_empty
        expect(vjas2.errors[:departure_time]).not_to be_blank
      end
    end

    context "when vjas does'nt exceed gap" do
      it "should not add errors" do
        expect(
          Chouette::VehicleJourneyAtStopsAreInIncreasingTimeOrderValidator
            .increasing_times_validate(vjas2, vjas1)
        ).to be_truthy
        expect(vjas2.errors).to be_empty
      end
    end
  end
end
