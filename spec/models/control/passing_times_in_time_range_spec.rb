# frozen_string_literal: true

RSpec.describe Control::PassingTimesInTimeRange do
  describe Control::PassingTimesInTimeRange::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: referential.workbench
    end

    let(:context) do
      Chouette.create do
        referential do
          vehicle_journey
        end
      end
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

    let(:referential) { context.referential }
    let(:vehicle_journey) { context.vehicle_journey }

    before do
      referential.switch

      vehicle_journey.vehicle_journey_at_stops.first.update arrival_time: "2000-01-01 17:00:00" , departure_time: "2000-01-01 17:00:00"

      control_run.run
    end

    describe '#run' do

      let(:after) { 58200 } # equals to 16:10
      let(:before) { 72600 } # equals to 20:10

      let(:expected_message) do
        an_object_having_attributes(
          source: vehicle_journey,
          criticity: 'warning',
          message_attributes: {
            'name' => vehicle_journey.published_journey_name
          }
        )
      end

      it { expect(control_run.control_messages).to include(expected_message) }
    end
  end
end

