# frozen_string_literal: true

RSpec.describe Control::PresenceCustomField do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::PresenceCustomField::Run do
    let(:context) do
      Chouette.create do
        custom_field
        referential
      end
    end
    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end
    let(:target_model) { 'StopArea' }
    let(:target_custom_field) { context.custom_field }
    subject(:control_run) do
      Control::PresenceCustomField::Run.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: { target_model: target_model, target_custom_field_id: target_custom_field.id },
        position: 0
      )
    end

    it { should validate_presence_of :target_model }
    it { should validate_presence_of :target_custom_field_id }
    it do
      should enumerize(:target_model).in(
        %w[Line StopArea Company JourneyPattern VehicleJourney]
      )
    end

    describe '#run' do
      subject { control_run.run }

      let(:expected_message) do
        an_object_having_attributes(
          source: source,
          message_key: 'presence_custom_field',
          criticity: 'warning',
          message_attributes: {
            'name' => source.try(:name) || source.id,
            'custom_field' => target_custom_field.code
          }
        )
      end

      describe '#StopArea' do
        let(:context) do
          Chouette.create do
            custom_field code: 'public_name', resource_type: 'StopArea'
            stop_area :stop_area
            referential do
              route stop_areas: [:stop_area]
            end
          end
        end

        let(:source) { context.stop_area(:stop_area) }
        let(:target_model) { 'StopArea' }

        before { context.referential.switch }

        context 'when a StopArea has no custom field value' do
          before { source.update custom_field_values: {} }

          it 'creates a warning message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'when a StopArea has custom field value' do
          before { source.update custom_field_values: { public_name: 'TEST' } }

          it 'has no warning message created' do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end

      describe '#Company' do
        let(:context) do
          Chouette.create do
            custom_field code: 'public_name', resource_type: 'Company'
            company
            referential
          end
        end

        let(:source) { context.company }
        let(:target_model) { 'Company' }
        let(:line) { context.referential.lines.first }

        before :each do
          line.update company: source
        end

        context 'when a Company has no custom field value' do
          before { source.update custom_field_values: { public_name: nil } }

          it 'creates a warning message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'when a Company has custom field value' do
          before { source.update custom_field_values: { public_name: 'TEST' } }

          it 'has no warning message created' do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end

      describe '#VehicleJourney' do
        let(:context) do
          Chouette.create do
            custom_field code: 'public_name', resource_type: 'VehicleJourney'
            referential do
              vehicle_journey
            end
          end
        end

        let(:source) { context.vehicle_journey }
        let(:target_model) { 'VehicleJourney' }

        before { context.referential.switch }

        context 'when a VehicleJourney has no custom field value' do
          before { source.update custom_field_values: { public_name: nil } }

          it 'creates a warning message' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end
        end

        context 'when a VehicleJourney has custom field value' do
          before { source.update custom_field_values: { public_name: 'TEST' } }

          it 'has no warning message created' do
            subject

            expect(control_run.control_messages).to be_empty
          end
        end
      end
    end
  end
end
