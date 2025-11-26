# frozen_string_literal: true

RSpec.describe Macro::RemoveAttributeValue do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end
end

RSpec.describe Macro::RemoveAttributeValue::Run do
  it { should validate_presence_of :target_model }
  it { should validate_presence_of :target_attribute }

  it do
    should enumerize(:target_model).in(
      %w[ 
        StopArea
        Company
        Line
        Entrance
        PointOfInterest
        Footnote
        VehicleJourney
        JourneyPattern
        Route
      ]
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
        target_attribute: target_attribute
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

        let(:context) do
          Chouette.create do
            stop_area :stop_area, city_name: 'Nantes'
          end
        end

        it 'should remove the attribute value' do
          expect { subject }.to change { stop_area.reload.city_name }.from('Nantes').to(nil)
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => stop_area.name
            },
            source: stop_area
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end

      describe '#coordinates' do
        let(:target_attribute) { 'coordinates' }

        let(:context) do
          Chouette.create do
            stop_area :stop_area, latitude: 48.1, longitude: 1.7
          end
        end

        it 'should remove latitude and longitude' do
          expect { subject }.to change { stop_area.reload.latitude }.from(48.1).to(nil)
                              .and change { stop_area.reload.longitude }.from(1.7).to(nil)
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

          expected_message = an_object_having_attributes(
            criticity: 'info',
            message_attributes: {
              'name' => stop_area.name
            },
            source: stop_area
          )
          expect(macro_run.macro_messages).to include(expected_message)
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
            line :line, transport_mode: 'bus', transport_submode: 'schoolBus'
          end
        end

        let(:expected_message) do
            an_object_having_attributes(
              criticity: 'info',
              message_attributes: {
                'name' => line.name
              },
              source: line
            )
        end

        it 'should remove transport_mode and transport_submode value' do
          expect { subject }
            .to change { line.reload.transport_mode }.from('bus').to(nil)
            .and change { line.reload.transport_submode }.from('schoolBus').to('undefined')
        end

        it 'should create a macro message' do
          expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end

