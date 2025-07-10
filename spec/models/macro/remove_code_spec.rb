# frozen_string_literal: true

RSpec.describe Macro::RemoveCode do
  it {
    is_expected.to validate_inclusion_of(:target_model).in_array(
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
  }
  it { is_expected.to validate_presence_of(:target_model) }
  it { is_expected.to validate_presence_of(:code_space_id) }

  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::RemoveCode::Run do
    let(:referential) { context.referential rescue nil } # rubocop:disable Style/RescueModifier
    let(:workbench) { context.workbench }

    let(:code_space) { context.code_space(:test) }
    let(:other_code_space) { context.code_space(:other) }
    let(:macro_list_run) do
      Macro::List::Run.create(
        workbench: workbench,
        referential: referential,
        creator: 'Test',
        name: 'Test run'
      )
    end
    let(:macro_run) do
      described_class.create!(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          target_model: target_model,
          code_space_id: code_space.id
        }
      )
    end

    describe '#run' do
      subject { macro_run.run }

      let(:model_name) { model.name }
      let(:expected_message) do
        an_object_having_attributes(
          message_attributes: {
            'name' => model_name,
            'codes_count' => 2
          }
        )
      end

      before { referential&.switch }

      context 'with StopArea' do
        let(:context) do
          Chouette.create do
            workgroup do
              code_space :test, short_name: 'test'
              code_space :other, short_name: 'other'
              workbench do
                stop_area codes: { 'test' => %w[first second], 'other' => 'unchanged' }
              end
            end
          end
        end
        let(:target_model) { 'StopArea' }
        let(:model) { context.stop_area }

        it 'should remove codes' do
          expect { subject }.to(
            change { model.reload.codes }.from(be_present).to(
              [have_attributes(code_space: other_code_space, value: 'unchanged')]
            )
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end

      context 'with Route' do
        let(:context) do
          Chouette.create do
            workgroup do
              code_space :test, short_name: 'test'
              code_space :other, short_name: 'other'
              workbench do
                referential do
                  route codes: { 'test' => %w[first second], 'other' => 'unchanged' }
                end
              end
            end
          end
        end
        let(:target_model) { 'Route' }
        let(:model) { context.route }

        it 'should remove codes' do
          expect { subject }.to(
            change { model.reload.codes }.from(be_present).to(
              [have_attributes(code_space: other_code_space, value: 'unchanged')]
            )
          )
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
