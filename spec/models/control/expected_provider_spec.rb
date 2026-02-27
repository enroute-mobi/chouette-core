# frozen_string_literal: true

RSpec.describe Control::ExpectedProvider do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::ExpectedProvider::Run do
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :expected_provider }
    it do
      should enumerize(:target_model).in(
        %w[
          StopArea ConnectionLink Entrance
          RoutingConstraint Company
          Line LineNotice Network
          Document PointOfInterest Shape
        ]
      )
    end

    describe "#run" do
      subject { control_run.run }

      let(:control_list_run) do
        Control::List::Run.create(referential: referential, workbench: workbench)
      end

      let(:control_run) do
        described_class.create(
          control_list_run: control_list_run,
          criticity: "warning",
          target_model: target_model,
          expected_provider: expected_provider,
          position: 0
        )
      end

      describe "Stop Area" do
        let(:context) do
          Chouette.create do
            workbench :current do
              stop_area :first, name: "First"
              stop_area :second, name: "Second"

              referential do
                route stop_areas: %i[first second]
              end
            end

            workbench :other do
              stop_area_provider :other
            end
          end
        end

        let(:workbench) { context.workbench(:current) }
        let(:referential) { context.referential }
        let(:target_model) { 'StopArea' }
        let(:faulty_stop_area) { context.stop_area(:second) }
        let(:criticity) { "warning" }

        let(:expected_message) do
          an_object_having_attributes({
            source: faulty_stop_area,
            criticity: criticity
          })
        end

        context 'when experted provider is all_workbench_provider' do
          let(:expected_provider) { 'all_workbench_provider' }

          before do
            referential.switch
            faulty_stop_area.update stop_area_provider: context.stop_area_provider(:other)
          end

          it 'includes the expected message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
  
        # For IBOO
        context 'when experted provider is workbench' do
          let(:expected_provider) { 'workbench' }
          let(:current_workbench) { context.workbench(:current) }

          before do
            referential.switch
            allow(current_workbench).to receive(:stop_areas).and_return([context.stop_area(:first)])
          end
          
          it 'includes the expected message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end
      end
    end
  end
end

