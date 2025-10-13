# frozen_string_literal: true

RSpec.describe Macro::ForceAttributeValue do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::ForceAttributeValue::Run do
  it { should validate_presence_of :target_model }
  it { should validate_presence_of :target_attribute }
  it { should validate_presence_of :expected_value }

  it do
    should enumerize(:target_model).in(
      %w[StopArea Company Line Entrance PointOfInterest]
    )
  end

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end

  let(:macro_run) do
    described_class.create(
      macro_list_run: macro_list_run,
      position: 0,
      options: {
        target_model: target_model,
        target_attribute: target_attribute,
        expected_value: expected_value
      }
    )
  end

  let(:context) do
    Chouette.create { workbench }
  end

  describe '#run' do
    subject { macro_run.run }

    describe 'StopArea' do
      let(:target_model) { 'StopArea' }
      let(:stop_area) { context.stop_area(:stop_area) }

      describe '#city_name' do
        let(:target_attribute) { 'city_name' }
        let(:expected_value) { 'Nantes' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, city_name: nil
          end
        end

        it 'should update the stop area with expected value' do
          expect { subject }.to change { stop_area.reload.city_name }.from(nil).to(expected_value)
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => stop_area.name,
              'target_attribute' => 'city_name'
            },
            source: stop_area
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end

      end

      describe '#referent' do
        let(:target_attribute) { 'is_referent' }
        let(:expected_value) { true }
        let(:referent) { context.stop_area(:referent) }
        let(:particular) { context.stop_area(:particular) }

        let(:context) do
          Chouette.create do
            stop_area :referent, is_referent: true
            stop_area :particular, time_zone: nil, referent: :referent
            stop_area :stop_area, is_referent: false
          end
        end

        describe '#candidate_models' do
          subject { macro_run.candidate_models }

          it { is_expected.to match_array([stop_area, particular]) }
        end

        it 'should update the stop area with expected value' do
          expect { subject }.to change { stop_area.reload.is_referent }.from(false).to(true)
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)

          expected_message_info = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => stop_area.name,
              'target_attribute' => 'is_referent'
            },
            source: stop_area
          )

          expected_message_error = an_object_having_attributes(
            criticity: 'error',
            message_attributes: {
              'name' => particular.name,
              'target_attribute' => 'is_referent'
            },
            source: particular
          )

          expect(macro_run.macro_messages).to include(expected_message_info)
          expect(macro_run.macro_messages).to include(expected_message_error)
        end

      end   
    end

    describe 'Line' do
      let(:target_model) { 'Line' }
      let(:line) { context.line(:line) }

      describe '#transport_mode' do
        let(:target_attribute) { 'transport_mode' }

        let(:context) do
          Chouette.create do
            line :line
          end
        end

        let(:expected_message) do
            an_object_having_attributes(
              criticity: 'info',
              message_attributes: {
                'name' => line.name,
                'target_attribute' => 'transport_mode'
              },
              source: line
            )
        end

        let(:transport_submode_value) { 'undefined' }

        before do
          line.update(
            chouette_transport_mode: Chouette::TransportMode.new(
              transport_mode_value,
              transport_submode_value
            )
          )
        end

        context 'when the expected value contains only mode' do
          let(:transport_mode_value) { 'tram' }
          let(:expected_value) { 'bus' }

          it 'should update the line with expected value' do
            expect { subject }.to change { line.reload.transport_mode }.from('tram').to(expected_value)
          end

          it 'should create a macro message' do
            expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context 'when the expected value contains mode and submode' do
          let(:transport_mode_value) { 'tram' }
          let(:expected_value) { 'bus/school_bus' }

          it 'should update the line with expected value' do
            expect { subject }.to change { line.reload.transport_mode }.from('tram').to('bus')
                              .and change { line.reload.transport_submode }.from('undefined').to('schoolBus')
          end

          it 'should create a macro message' do
            expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context 'when the expected value is the same mode but different submode' do
          let(:transport_mode_value) { 'bus' }
          let(:expected_value) { 'bus/school_bus' }

          it 'should update the line with expected value' do
            expect {
              subject
            }.to change {
              line.reload.attributes.slice('transport_mode', 'transport_submode')
            }.from({
              'transport_mode' => 'bus',
              'transport_submode' => 'undefined'
            }).to({
              'transport_mode' => 'bus',
              'transport_submode' => 'schoolBus'
            })
          end

          it 'should create a macro message' do
            expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end
    end
  end
end
