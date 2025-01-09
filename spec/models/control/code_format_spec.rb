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
        %w[
          Line
          LineGroup
          LineNotice
          Company
          StopArea
          StopAreaGroup
          Entrance
          Shape
          PointOfInterest
          ServiceFacilitySet
          AccessibilityAssessment
          Fare::Zone
          LineRoutingConstraintZone
          Document
          Contract
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ]
      )
    end

    let(:control_list_run) do
      Control::List::Run.create(referential: referential, workbench: context.workbench)
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
    let(:referential) { nil }

    describe '#run' do
      subject { control_run.run }

      let(:expected_message) do
        an_object_having_attributes(
          source: source,
          criticity: 'warning',
          message_attributes: {
            'name' => source.try(:name) || source.try(:published_journey_name) || source.try(:comment),
            'code_space_name' => 'test',
            'expected_format' => expected_format
          },
          message_key: 'code_format'
        )
      end

      before { referential&.switch }

      describe '#StopArea' do
        let(:target_model) { 'StopArea' }
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            stop_area :without_code
            stop_area :with_a_good_code, codes: { test: 'B9999-AAA' }
            stop_area :with_a_bad_code, codes: { test: 'BAD_CODE' }
          end
        end
        let(:source) { context.stop_area(:with_a_bad_code) }

        it 'should create a warning message only for the StopArea with a bad code' do
          subject
          expect(control_run.control_messages).to match_array([expected_message])
        end

        context 'when expected_format is just numbers' do
          let(:expected_format) { '123' }

          it 'does not crash' do
            expect { subject }.to_not raise_error
          end
        end
      end

      describe '#PointOfInterest' do
        let(:target_model) { 'PointOfInterest' }
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            point_of_interest :without_code
            point_of_interest :with_a_good_code, codes: { test: 'B9999-AAA' }
            point_of_interest :with_a_bad_code, codes: { test: 'BAD_CODE' }
          end
        end
        let(:source) { context.point_of_interest(:with_a_bad_code) }

        it 'should create a warning message only for the StopArea with a bad code' do
          subject
          expect(control_run.control_messages).to match_array([expected_message])
        end
      end

      describe '#VehicleJourney' do
        let(:target_model) { 'VehicleJourney' }
        let(:context) do
          Chouette.create do
            code_space short_name: 'test'
            referential do
              vehicle_journey :without_code
              vehicle_journey :with_a_good_code, codes: { test: 'B9999-AAA' }
              vehicle_journey :with_a_bad_code, codes: { test: 'BAD_CODE' }
            end
          end
        end
        let(:referential) { context.referential }
        let(:source) { context.vehicle_journey(:with_a_bad_code) }

        it 'should create a warning message only for the VehicleJourney with a bad code' do
          subject
          expect(control_run.control_messages).to match_array([expected_message])
        end
      end
    end
  end
end
