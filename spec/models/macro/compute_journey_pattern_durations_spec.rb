# frozen_string_literal: true

RSpec.describe Macro::ComputeJourneyPatternDurations do
  it 'should be one of the available Macro' do
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

    let!(:first_stop) { first_at_stop.stop_point.stop_area }
    let!(:second_stop) { second_at_stop.stop_point.stop_area }
    let!(:third_stop) { third_at_stop.stop_point.stop_area }
    let!(:fourth_stop) { fourth_at_stop.stop_point.stop_area }
    let!(:fifth_stop) { fifth_at_stop.stop_point.stop_area }
    let!(:sixth_stop) { sixth_at_stop.stop_point.stop_area }

    let(:time) { Time.now }

    describe '#run' do
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

      it 'should compute and update Journey Pattern costs' do
        exported_costs = {
          "#{first_stop.id}-#{second_stop.id}" => { 'time' => 300 },
          "#{second_stop.id}-#{third_stop.id}" => { 'time' => 300 },
          "#{third_stop.id}-#{fourth_stop.id}" => { 'time' => 300 },
          "#{fourth_stop.id}-#{fifth_stop.id}" => { 'time' => 300 },
          "#{fifth_stop.id}-#{sixth_stop.id}" => { 'time' => 300 }
        }
        expect { subject }.to change { journey_pattern.reload.costs }.to(exported_costs)
      end

      it 'creates a message for each journey_pattern' do
        subject

        expect(macro_run.macro_messages).to include(
          an_object_having_attributes({
                                        criticity: 'info',
                                        message_attributes: { 'name' => 'journey pattern name 1' },
                                        source: journey_pattern
                                      })
        )
      end
    end
  end
end
