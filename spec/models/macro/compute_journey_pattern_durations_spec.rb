# frozen_string_literal: true

RSpec.describe Macro::ComputeJourneyPatternDurations do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::ComputeJourneyPatternDurations::Run do
    subject(:macro_run) { described_class.create!(macro_list_run: macro_list_run, position: 0) }

    let(:context) do
      Chouette.create do
        workbench do
          stop_area :stop_area1
          stop_area :stop_area2
          stop_area :stop_area3
          stop_area :stop_area4
          stop_area :stop_area5
          stop_area :stop_area6

          referential do
            route with_stops: false do
              stop_point stop_area: :stop_area1
              stop_point stop_area: :stop_area2
              stop_point stop_area: :stop_area3
              stop_point stop_area: :stop_area4
              stop_point stop_area: :stop_area5
              stop_point stop_area: :stop_area6

              journey_pattern name: 'journey pattern name 1', costs: {} do
                vehicle_journey
              end
            end
          end
        end
      end
    end
    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:journey_pattern) { context.journey_pattern }
    let(:first_stop) { context.stop_area(:stop_area1) }
    let(:second_stop) { context.stop_area(:stop_area2) }
    let(:third_stop) { context.stop_area(:stop_area3) }
    let(:fourth_stop) { context.stop_area(:stop_area4) }
    let(:fifth_stop) { context.stop_area(:stop_area5) }
    let(:sixth_stop) { context.stop_area(:stop_area6) }
    let(:macro_list_run) { workbench.macro_list_runs.new(referential: referential) }

    describe '#run' do
      subject { macro_run.run }

      before { referential.switch }

      it 'should compute and update Journey Pattern costs' do
        exported_costs = {
          "#{first_stop.id}-#{second_stop.id}" => { 'time' => 240 },
          "#{second_stop.id}-#{third_stop.id}" => { 'time' => 240 },
          "#{third_stop.id}-#{fourth_stop.id}" => { 'time' => 240 },
          "#{fourth_stop.id}-#{fifth_stop.id}" => { 'time' => 240 },
          "#{fifth_stop.id}-#{sixth_stop.id}" => { 'time' => 240 }
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
