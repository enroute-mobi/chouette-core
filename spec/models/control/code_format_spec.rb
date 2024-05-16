# frozen_string_literal: true

RSpec.describe Control::CodeFormat do
  it 'should be one of the available Control' do
    expect(Control.available).to include(described_class)
  end

  describe Control::CodeFormat::Run do
    let(:expected_format) { '[BFHJ][0-9]{4,6}-[A-Z]{3}' }
    it { should validate_presence_of :target_model }
    it { should validate_presence_of :target_code_space_id }
    it { should validate_presence_of :expected_format }
    it do
      should enumerize(:target_model).in(
        %w[Line StopArea VehicleJourney Shape]
      )
    end

    let(:control_list_run) do
      Control::List::Run.create referential: context.referential, workbench: context.workbench
    end

    let(:control_run) do
      Control::CodeFormat::Run.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: {
          target_model: target_model,
          target_code_space_id: target_code_space_id,
          expected_format: expected_format
        },
        position: 0
      )
    end

    let(:target_code_space_id) { context.code_space.id }
    let(:referential) { context.referential }

    describe '#run' do
      subject { control_run.run }

      let(:expected_message) do
        an_object_having_attributes(
          source: source,
          criticity: 'warning',
          message_attributes: {
            'name' => source.try(:name) || source.id,
            'code_space_name' => 'test',
            'expected_format' => expected_format
          },
          message_key: 'code_format'
        )
      end

      before { referential.switch }

      describe '#StopArea' do
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            stop_area :with_a_good_code, codes: { test: 'B9999-AAA' }
            stop_area :with_a_bad_code, codes: { test: 'BAD_CODE' }
            referential do
              route stop_areas: %i[with_a_good_code with_a_bad_code]
            end
          end
        end

        let(:target_model) { 'StopArea' }
        let(:source) { context.stop_area(:with_a_bad_code) }
        let(:stop_area_with_a_good_code) { context.stop_area(:with_a_good_code) }

        let(:message_for_good_code) do
          control_run.control_messages.find { |msg| msg.source == stop_area_with_a_good_code }
        end

        context "when a StopArea exists a space code 'test'" do
          it 'should create a warning message for the StopArea with a bad code' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end

          it 'should not create a warning message for the StopArea with a good code' do
            subject

            expect(message_for_good_code).to be_nil
          end
        end

        context 'when expected_format is just numbers' do
          let(:expected_format) { '123' }

          it 'does not crash' do
            expect { subject }.to_not raise_error
          end
        end
      end

      describe '#VehicleJourney' do
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            referential do
              vehicle_journey :with_a_good_code
              vehicle_journey :with_a_bad_code
            end
          end
        end

        let(:target_model) { 'VehicleJourney' }
        let(:source) { context.vehicle_journey(:with_a_bad_code) }
        let(:vehicle_journey_with_a_good_code) { context.vehicle_journey(:with_a_good_code) }
        let(:vehicle_journey_with_a_bad_code) { context.vehicle_journey(:with_a_bad_code) }
        let(:message_for_good_code) do
          control_run.control_messages.find { |msg| msg.source == vehicle_journey_with_a_good_code }
        end

        before do
          vehicle_journey_with_a_good_code.codes.create(value: 'B9999-AAA', code_space: context.code_space)
          vehicle_journey_with_a_bad_code.codes.create(value: 'BAD_CODE', code_space: context.code_space)
        end

        context "when a VehicleJourney exists a space code 'test'" do
          it 'should create a warning message for the VehicleJourney with a bad code' do
            subject

            expect(control_run.control_messages).to include(expected_message)
          end

          it 'should not create a warning message for the VehicleJourney with a good code' do
            subject

            expect(message_for_good_code).to be_nil
          end
        end
      end
    end
  end
end
