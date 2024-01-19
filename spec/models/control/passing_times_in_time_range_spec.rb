# frozen_string_literal: true

RSpec.describe Control::PassingTimesInTimeRange do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::PassingTimesInTimeRange::Run do
    it { should validate_presence_of :passing_time_scope }
    it do
      should enumerize(:passing_time_scope).in(
        %w[all first last]
      )
    end

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
        passing_time_scope: passing_time_scope,
        after: after,
        before: before,
        position: 0
      )
    end

    let(:referential) { context.referential }
    let(:vehicle_journey) { context.vehicle_journey }

    let(:first_vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.first }
    let(:second_vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.second }
    let(:last_vehicle_journey_at_stop) { vehicle_journey.vehicle_journey_at_stops.last }

    before do
      referential.switch
    end

    describe '#run' do

      let(:expected_message) do
        an_object_having_attributes(
          source: vehicle_journey,
          criticity: 'warning',
          message_attributes: {
            'name' => vehicle_journey.published_journey_name,
          }
        )
      end

      context "when after is equal to '16:10' and before is equal to '20:10'" do
        let(:after) { 58200 }
        let(:before) { 72600 }

        context "when passing_time_scope is 'all'" do
          let(:passing_time_scope) { 'all' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to contain_exactly(expected_message) }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end

        context "when passing_time_scope is 'first'" do
          let(:passing_time_scope) { 'first' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'
              control_run.run
            end

            it { expect(control_run.control_messages).to contain_exactly(expected_message) }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end

        context "when passing_time_scope is 'last'" do
          let(:passing_time_scope) { 'last' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to contain_exactly(expected_message) }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end
      end

      context "when after is equal to '00:00' and before is equal to '00:00'" do
        let(:after) { '' } # -infinity
        let(:before) { '' } # infinity

        context "when passing_time_scope is 'all'" do
          let(:passing_time_scope) { 'all' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end

        context "when passing_time_scope is 'first'" do
          let(:passing_time_scope) { 'first' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'
              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end

        context "when passing_time_scope is 'last'" do
          let(:passing_time_scope) { 'last' }

          context 'and exists at least one at_stop that is not in time range' do
            before do
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 11:00:00', departure_time: '2000-01-01 11:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end

          context 'and all at_stops are in time range' do
            before do
              first_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              second_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'
              last_vehicle_journey_at_stop.update arrival_time: '2000-01-01 17:00:00', departure_time: '2000-01-01 17:00:00'

              control_run.run
            end

            it { expect(control_run.control_messages).to be_empty }
          end
        end
      end
    end
  end
end
