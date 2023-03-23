# frozen_string_literal: true

RSpec.describe Control::PassingTimesInTimeRange do
  describe Control::PassingTimesInTimeRange::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: referential.workbench
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        passing_time_scope: 'all',
        after: after,
        before: before,
        position: 0
      )
    end

    let(:referential) { create(:vehicle_journey_at_stop).vehicle_journey.referential }
    let(:current_date) { Date.current }

    let(:at_stop_in_time_range) { referential.reload.vehicle_journey_at_stops.first }
    let(:at_stop_not_in_time_range) { referential.reload.vehicle_journey_at_stops.second }

    before do
      referential.switch

      at_stop_in_time_range.update arrival_time: "2000-01-01 17:00:00" , departure_time: "2000-01-01  17:00:00"
      at_stop_not_in_time_range.update arrival_time: "2000-01-01 22:00:00" , departure_time: "2000-01-01 23:00:00"

      control_run.run
    end 

    describe '#run' do

      let(:after) { "16:10 day:0" }
      let(:before) { "20:10 day:0" }

      let(:expected_message) do
        an_object_having_attributes(
          source: at_stop_not_in_time_range,
          criticity: 'warning',
          message_attributes: {
            'name' => at_stop_not_in_time_range.id,
            'departure_time' => at_stop_not_in_time_range.departure_time,
            'arrival_time' => at_stop_not_in_time_range.arrival_time
          }
        )
      end

      let(:not_expected_message) do
        an_object_having_attributes(
          source: at_stop_in_time_range,
          criticity: 'warning',
        )
      end

      it { expect(control_run.control_messages).to include(expected_message) }
      it { expect(control_run.control_messages).to_not include(not_expected_message) }
    end
  end
end

