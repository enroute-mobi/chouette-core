# frozen_string_literal: true

RSpec.describe Control::CodeUniqueness do
  describe Control::CodeUniqueness::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
    end

    let(:context) do
      Chouette.create do
        code_space short_name: "test"

        stop_area :first
        stop_area :second
        stop_area :last

        referential do
          route stop_areas: %i[first second last] do
            journey_pattern
          end
        end

        stop_area_provider :other
        workbench :other
        workgroup :other do
          code_space short_name: "test"
        end
      end
    end

    let(:control_run) do
      described_class.create(
        control_list_run: control_list_run,
        criticity: 'warning',
        options: { 
          target_model: target_model,
          target_code_space_id: target_code_space.id,
          uniqueness_scope: uniqueness_scope
        },
        position: 0
      )
    end

    let(:referential) { context.referential }
    let(:workbench) { referential.workbench }
    let(:workgroup) { workbench.workgroup }

    let(:first_duplicate_stop) { context.stop_area :first }
    let(:second_duplicate_stop) { context.stop_area :second }
    let(:not_expected_stop) { context.stop_area :last }

    let(:stop_area_provider) { first_duplicate_stop.stop_area_provider }

    let(:other_workgroup) { context.workgroup :other }
    let(:other_workbench) { context.workbench :other }
    let(:other_stop_area_provider) { context.stop_area_provider :other }

    let(:target_code_space) { workgroup.code_spaces.find_by(short_name: 'test') }

    before { referential.switch }

    subject do
      control_run.run
      control_run.control_messages
    end

    describe '#run' do
      describe '#stop_areas' do
        let(:target_model) { 'StopArea' }

        let(:first_expected_message) do
          an_object_having_attributes(
            message_attributes: {
              'name' => first_duplicate_stop.name,
              'code_space' => 'test',
              'code_value' => 'dummy'
            },
            source: first_duplicate_stop,
            criticity: 'warning'
          )
        end

        let(:second_expected_message) do
          an_object_having_attributes(
            source: second_duplicate_stop,
            message_attributes: {
              'name' => second_duplicate_stop.name,
              'code_space' => 'test',
              'code_value' => 'dummy'
            },
            criticity: 'warning'
          )
        end

        let(:not_expected_message) do
          an_object_having_attributes(
            source: not_expected_stop,
            criticity: 'warning'
          )
        end

        before do
          first_duplicate_stop.codes.create(code_space: target_code_space, value: 'dummy')
          second_duplicate_stop.codes.create(code_space: target_code_space, value: 'dummy')
        end

        context "When uniqueness scope is 'Provider'" do
          let(:uniqueness_scope) { 'provider' }

          context 'with the same provider' do
            it 'should create warning messages' do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end

            it 'should not ccreate message for the last stop area' do
              is_expected.not_to include(not_expected_message)
            end
          end

          context 'with other provider' do
            before do
              first_duplicate_stop.update stop_area_provider: other_stop_area_provider
            end

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workbench'" do
          let(:uniqueness_scope) { 'workbench' }

          before do
            first_duplicate_stop.update stop_area_provider: other_stop_area_provider
          end

          context 'with the same workbench' do
            it 'should create warning messages' do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end
          end

          context 'with other workbench' do
            before do
              stop_area_provider.update workbench: other_workbench
            end

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workgroup'" do
          let(:uniqueness_scope) { 'workgroup' }

          context 'with the same workgroup' do
            before do
              other_stop_area_provider.update workbench: other_workbench
              first_duplicate_stop.update stop_area_provider: other_stop_area_provider
            end

            let(:target_code_space) { other_workgroup.code_spaces.find_by(short_name: 'test') }

            it 'should create warning messages' do
              is_expected.to include(first_expected_message)
              is_expected.to include(second_expected_message)
            end

            it 'should not create message for the last stop area' do
              is_expected.not_to include(not_expected_message)
            end
          end

          context 'with other workgroup' do
            before do
              other_workbench.update workgroup: other_workgroup
              other_stop_area_provider.update workbench: other_workbench
              first_duplicate_stop.update stop_area_provider: other_stop_area_provider
            end

            let(:target_code_space) { other_workgroup.code_spaces.find_by(short_name: 'test') }

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end
      end
    end
  end
end
