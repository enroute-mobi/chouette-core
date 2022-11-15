RSpec.describe Macro::ComputeJourneyPatternDurations do

  it "should be one of the available Macro" do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::ComputeJourneyPatternDurations::Run do
    let(:macro_run) { Macro::ComputeJourneyPatternDurations::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: referential.workbench
    end

    let!(:at_stop) { create(:vehicle_journey_at_stop) }
    let!(:vehicle_journey) { at_stop.vehicle_journey }
    let!(:journey_pattern) { vehicle_journey.journey_pattern }
    let!(:referential) { journey_pattern.referential }

    let!(:first_at_stop) { journey_pattern.vehicle_journey_at_stops.first }
    let!(:second_at_stop) { journey_pattern.vehicle_journey_at_stops.second }
    let!(:third_at_stop) { journey_pattern.vehicle_journey_at_stops.third }
    let!(:fourth_at_stop) { journey_pattern.vehicle_journey_at_stops.fourth }
    let!(:fifth_at_stop) { journey_pattern.vehicle_journey_at_stops.fifth }
    let!(:sixth_at_stop) { journey_pattern.vehicle_journey_at_stops.last }

    let(:time) { Time.now }


    describe "#run" do
      subject { macro_run.run }

      before do
        journey_pattern.update name: 'journey pattern name 1', costs: {}

        first_at_stop.update arrival_time: time, departure_time: time
        second_at_stop.update arrival_time: time + 5.minutes, departure_time: time + 5.minutes
        third_at_stop.update arrival_time: time + 10.minutes, departure_time: time + 10.minutes
        fourth_at_stop.update arrival_time: time + 15.minutes, departure_time: time + 15.minutes
        fifth_at_stop.update arrival_time: time + 20.minutes, departure_time: time + 20.minutes
        sixth_at_stop.update arrival_time: time + 25.minutes, departure_time: time + 25.minutes
      end

      it "should compute and update Journey Pattern costs" do
        expect { subject }.to change { journey_pattern.reload.costs }.to({
          "1-2"=>{"time"=>300},
          "2-3"=>{"time"=>300},
          "3-4"=>{"time"=>300},
          "4-5"=>{"time"=>300},
          "5-6"=>{"time"=>300}
        })
      end

      it "creates a message for each journey_pattern" do
        subject

        expect(macro_run.macro_messages).to include(
          an_object_having_attributes({
            criticity: "info",
            message_attributes: { "name"=>"journey pattern name 1" },
            source: journey_pattern
          })
        )
      end
    end
  end
end
