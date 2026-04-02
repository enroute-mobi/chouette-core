# frozen_string_literal: true

RSpec.describe Control::CodeUniqueness do
  describe 'validations' do
    describe 'on #uniqueness_scope' do
      context 'when #target_model is a provider model' do
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
        ].each do |target_model|
          context "when #target_model is \"#{target_model}\"" do
            before { subject.target_model = target_model }
            it { is_expected.to allow_value('workgroup').for(:uniqueness_scope) }
            it { is_expected.to allow_value('workbench').for(:uniqueness_scope) }
            it { is_expected.to allow_value('provider').for(:uniqueness_scope) }
            it { is_expected.not_to allow_value('referential').for(:uniqueness_scope) }
          end
        end
      end

      context 'when #target_model is a workbench model' do
        %w[
          Contract
        ].each do |target_model|
          context "when #target_model is \"#{target_model}\"" do
            before { subject.target_model = target_model }
            it { is_expected.to allow_value('workgroup').for(:uniqueness_scope) }
            it { is_expected.to allow_value('workbench').for(:uniqueness_scope) }
            it { is_expected.not_to allow_value('provider').for(:uniqueness_scope) }
            it { is_expected.not_to allow_value('referential').for(:uniqueness_scope) }
          end
        end
      end

      context 'when #target_model is a referential model' do
        %w[
          Route
          JourneyPattern
          VehicleJourney
          TimeTable
        ].each do |target_model|
          context "when #target_model is \"#{target_model}\"" do
            before { subject.target_model = target_model }
            it { is_expected.not_to allow_value('workgroup').for(:uniqueness_scope) }
            it { is_expected.not_to allow_value('workbench').for(:uniqueness_scope) }
            it { is_expected.not_to allow_value('provider').for(:uniqueness_scope) }
            it { is_expected.to allow_value('referential').for(:uniqueness_scope) }
          end
        end
      end
    end
  end

  describe Control::CodeUniqueness::Run do
    let(:control_list_run) do
      Control::List::Run.create referential: referential, workbench: workbench
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
    let(:workbench) { context.workbench }
    let(:workgroup) { workbench.workgroup }

    let(:first_duplicate_stop) { context.stop_area :first }
    let(:second_duplicate_stop) { context.stop_area :second }

    let(:target_code_space) { workgroup.code_spaces.find_by(short_name: 'test') }

    subject do
      control_run.run
      control_run.control_messages
    end

    describe '#run' do
      describe '#stop_areas' do
        let(:target_model) { 'StopArea' }
        let(:referential) { nil }

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

        context "When uniqueness scope is 'Provider'" do
          let(:uniqueness_scope) { 'provider' }

          context 'and the stop areas have the same provider' do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'

                stop_area :first, codes: { 'test' => 'dummy' }
                stop_area :second, codes: { 'test' => 'dummy' }
                stop_area :last
              end
            end

            it 'should create warning messages for first and second stop areas but not for the last one' do
              is_expected.to contain_exactly(first_expected_message, second_expected_message)
            end
          end

          context 'and the stop areas have different providers' do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'

                stop_area_provider do
                  stop_area :first, codes: { 'test' => 'dummy' }
                end

                stop_area_provider do
                  stop_area :second, codes: { 'test' => 'dummy' }
                end
              end
            end

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workbench'" do
          let(:uniqueness_scope) { 'workbench' }

          context 'and the stop areas are in the same workbench' do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'

                stop_area :first, codes: { 'test' => 'dummy' }
                stop_area :second, codes: { 'test' => 'dummy' }
                stop_area :last
              end
            end

            it 'should create warning messages for first and second stop areas but not for the last one' do
              is_expected.to contain_exactly(first_expected_message, second_expected_message)
            end
          end

          context 'and the stop areas are in different workbenches' do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'

                workbench :first_workbench do
                  stop_area :first, codes: { 'test' => 'dummy' }
                end

                workbench :second_workbench do
                  stop_area :second, codes: { 'test' => 'dummy' }
                end
              end
            end

            let(:workbench) { context.workbench(:first_workbench) }

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end

        context "When uniqueness scope is 'Workgroup'" do
          let(:uniqueness_scope) { 'workgroup' }

          context 'and the stop areas are in the same workgroup but not in the same workbench' do
            let(:context) do
              Chouette.create do
                workgroup :workgroup do
                  code_space short_name: 'test'

                  workbench :first_workbench do
                    stop_area_provider :first_stop_area_provider do
                      stop_area :first, codes: { 'test' => 'dummy' }
                    end
                  end

                  workbench :second_workbench do
                    stop_area_provider :second_stop_area_provider do
                      stop_area :second, codes: { 'test' => 'dummy' }
                    end
                  end
                end
              end
            end

            let(:workbench) { context.workbench(:first_workbench) }

            it 'should create warning messages for the first and second stop areas' do
              is_expected.to contain_exactly(first_expected_message, second_expected_message)
            end
          end

          context 'and the stop areas are in different workgroups' do
            let(:context) do
              Chouette.create do
                workgroup :first_workgroup do
                  code_space short_name: 'test'

                  workbench :first_workbench do
                    stop_area_provider :first_stop_area_provider do
                      stop_area :first, codes: { 'test' => 'dummy' }
                    end
                  end
                end

                workgroup :second_workgroup do
                  code_space short_name: 'test'

                  workbench :second_workbench do
                    stop_area_provider :second_stop_area_provider do
                      stop_area :second, codes: { 'test' => 'dummy' }
                    end
                  end
                end
              end
            end

            let(:workbench) { context.workbench(:first_workbench) }
            let(:target_code_space) { context.workgroup(:first_workgroup).code_spaces.find_by(short_name: 'test') }

            it 'should not create warning messages' do
              is_expected.to be_empty
            end
          end
        end
      end
    end
  end
end
