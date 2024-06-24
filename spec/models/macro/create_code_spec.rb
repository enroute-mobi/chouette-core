# frozen_string_literal: true

RSpec.describe Macro::CreateCode do
  subject(:macro) { Macro::CreateCode.new }

  it {
    is_expected.to validate_inclusion_of(:target_model)
      .in_array(%w[StopArea Line VehicleJourney])
  }
  it { is_expected.to validate_presence_of(:source_attribute) }
  it { is_expected.to_not validate_presence_of(:source_pattern) }
  it { is_expected.to validate_presence_of(:target_code_space) }
  it { is_expected.to_not validate_presence_of(:target_pattern) }

  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateCode::Run do
    describe '#models_without_code' do
      subject { macro_run.models_without_code }

      context "when the macro has target_model 'StopArea' and target_code_space 'test'" do
        let!(:macro_list_run) do
          Macro::List::Run.create workbench: context.workbench
        end

        let(:macro_run) do
          Macro::CreateCode::Run.new(
            macro_list_run: macro_list_run,
            target_model: 'StopArea',
            target_code_space: 'test'
          ).tap do |run|
            allow(run).to receive(:workbench).and_return(context.workbench)
          end
        end

        context 'when a StopArea exists without code' do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              stop_area
              referential
            end
          end
          let(:stop_area) { context.stop_area }

          it 'includes the Stop Area' do
            is_expected.to include(stop_area)
          end
        end

        context 'when a StopArea exists with another code' do
          let(:context) do
            Chouette.create do
              code_space short_name: 'other'
              stop_area codes: { other: 'dummy' }
              referential
            end
          end
          let(:stop_area) { context.stop_area }

          it 'includes the Stop Area' do
            is_expected.to include(stop_area)
          end
        end

        context "when a StopArea exists a code 'test'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              stop_area codes: { test: 'dummy' }
              referential
            end
          end
          let(:stop_area) { context.stop_area }

          it "doesn't include the Stop Area" do
            is_expected.to_not include(stop_area)
          end
        end
      end
    end

    describe '#run' do
      subject { macro_run.run }

      context "when the macro has target_model 'StopArea'" do
        let!(:macro_list_run) do
          Macro::List::Run.create workbench: context.workbench
        end
        let(:macro_run) do
          Macro::CreateCode::Run.create(
            target_model: 'StopArea',
            source_attribute: source_attribute,
            target_code_space: 'test',
            macro_list_run: macro_list_run,
            position: 0
          ).tap do |run|
            allow(run).to receive(:workbench).and_return(context.workbench)
          end
        end

        let(:stop_area) { context.stop_area }

        context "source_attribute 'registration_number' and target_code_space 'test'" do
          let(:source_attribute) { 'registration_number' }

          context "when a StopArea exists with a registration_number 'dummy'" do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'
                stop_area registration_number: 'dummy'
                referential
              end
            end
            let(:code_space) { context.code_space }

            it "creates a code 'test' with value 'dummy' for this Stop Area" do
              expected_change = change { stop_area.codes.find_by(code_space: code_space)&.value }
                                .from(nil).to('dummy')
              expect { subject }.to expected_change
            end

            context "when a StopArea exists with a code 'test'" do
              let(:context) do
                Chouette.create do
                  code_space short_name: 'test'
                  stop_area registration_number: 'dummy', codes: { test: 'unchanged' }
                  referential
                end
              end

              it "doesn't change the existing code for this Stop Area" do
                change_code_value = change { stop_area.codes.find_by(code_space: code_space)&.value }
                expect { subject }.to_not change_code_value
              end
            end

            context "when a StopArea exists with a code 'other_test'" do
              let(:context) do
                Chouette.create do
                  code_space :code_test, short_name: 'test'
                  code_space :other_code_space, short_name: 'other_test'
                  stop_area registration_number: 'dummy', codes: { other_test: 'unchanged' }
                  referential
                end
              end
              let(:code_space) { context.code_space(:code_test) }

              it "creates a code 'test' with value 'dummy' for this Stop Area" do
                expected_change = change { stop_area.codes.find_by(code_space: code_space)&.value }
                                  .from(nil).to('dummy')
                expect { subject }.to expected_change
              end
            end
          end

          context 'when a StopArea exists without a registration_number' do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'
                stop_area registration_number: nil
                referential
              end
            end

            it "doesn't create a code" do
              expect { subject }.to_not(change { stop_area.reload.codes.count })
            end
          end
        end

        context "source_attribute 'code:other_test' and target_code_space 'test'" do
          let(:source_attribute) { 'code:other_test' }

          context "when a StopArea exists with a code 'other_test' 'dummy'" do
            let(:context) do
              Chouette.create do
                code_space :code_space_test, short_name: 'test'
                code_space :code_space_other_test, short_name: 'other_test'
                stop_area codes: { other_test: 'dummy' }
                referential
              end
            end
            let(:code_space) { context.code_space(:code_space_test) }

            it "creates a code 'test' with value 'dummy' for this Stop Area" do
              expected_change = change { stop_area.codes.find_by(code_space: code_space)&.value }
                                .from(nil).to('dummy')
              expect { subject }.to expected_change
            end
          end

          context "when a StopArea exists without a code 'other_test'" do
            let(:context) do
              Chouette.create do
                code_space :code_space_test, short_name: 'test'
                code_space :code_space_other_test, short_name: 'other_test'
                stop_area
                referential
              end
            end

            it "doesn't create a code" do
              expect { subject }.to_not(change { stop_area.reload.codes.count })
            end
          end
        end
      end

      context "when the macro has target_model 'Line', source_attribute 'number' and target_code_space 'test'" do
        let!(:macro_list_run) do
          Macro::List::Run.create workbench: context.workbench
        end
        let(:macro_run) do
          Macro::CreateCode::Run.create(
            target_model: 'Line',
            source_attribute: 'number',
            target_code_space: 'test',
            macro_list_run: macro_list_run,
            position: 0
          ).tap do |run|
            allow(run).to receive(:workbench).and_return(context.workbench)
          end
        end

        let(:line) { context.line }

        context "when a Line exists with a number 'dummy'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              line number: 'dummy'
              referential
            end
          end
          let(:code_space) { context.code_space }

          it "creates a code 'test' with value 'dummy' for this Line" do
            expected_change = change { line.codes.find_by(code_space: code_space)&.value }
                              .from(nil).to('dummy')
            expect { subject }.to expected_change
          end
        end
      end

      context "when the macro has target_model 'VehicleJourney' target_code_space 'test'" do
        let(:macro_list_run) do
          Macro::List::Run.create referential: context.referential, workbench: context.workbench
        end
        let(:macro_run) do
          Macro::CreateCode::Run.create(
            target_model: 'VehicleJourney',
            source_attribute: 'published_journey_identifier',
            target_code_space: 'test',
            macro_list_run: macro_list_run,
            position: 0
          )
        end

        let(:vehicle_journey) { context.vehicle_journey }

        before { context.referential.switch }

        context "when a VehicleJourney exists with a published_journey_identifier 'dummy'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              vehicle_journey published_journey_identifier: 'dummy'
            end
          end
          let(:code_space) { context.code_space }

          it "creates a code 'test' with value 'dummy' for this Vehicle Journey" do
            expected_change = change { vehicle_journey.codes.find_by(code_space: code_space)&.value }
                              .from(nil).to('dummy')
            expect { subject }.to expected_change
          end

          context "when a VehicleJourney exists with a code 'test'" do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'
                vehicle_journey published_journey_identifier: 'dummy', codes: { test: 'unchanged' }
              end
            end

            it "doesn't change the existing code for this Vehicle Journey" do
              change_code_value = change { vehicle_journey.codes.find_by(code_space: code_space)&.value }
              expect { subject }.to_not change_code_value
            end
          end

          context "when a VehicleJourney exists with a code 'other_test'" do
            let(:context) do
              Chouette.create do
                code_space :code_test, short_name: 'test'
                code_space :other_code_space, short_name: 'other_test'
                vehicle_journey published_journey_identifier: 'dummy', codes: { other_test: 'unchanged' }
              end
            end
            let(:code_space) { context.code_space(:code_test) }

            it "creates a code 'test' with value 'dummy' for this Vehicle Journey" do
              expected_change = change { vehicle_journey.codes.find_by(code_space: code_space)&.value }
                                .from(nil).to('dummy')
              expect { subject }.to expected_change
            end
          end
        end

        context 'when a VehicleJourney exists without a published_journey_identifier ' do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              vehicle_journey published_journey_identifier: nil
            end
          end

          it "doesn't create a code" do
            expect { subject }.to_not(change { vehicle_journey.reload.codes.count })
          end
        end
      end
    end
  end

  describe Macro::CreateCode::Source do
    subject(:source) { Macro::CreateCode::Source.new }

    context '#raw_value' do
      subject { source.raw_value(model) }

      context "when attribute is 'registration_number'" do
        before { source.attribute = 'registration_number' }

        context "when model is a StopArea with registration_number 'dummy'" do
          let(:context) { Chouette.create { stop_area registration_number: 'dummy' } }
          let(:model) { context.stop_area }

          it { is_expected.to eq('dummy') }
        end
      end

      context "when attribute is 'code:test'" do
        before { source.attribute = 'code:test' }

        before { source.workgroup = context.workgroup }

        context "when model is a StopArea with a code 'test' with value 'dummy'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              stop_area codes: { test: 'dummy' }
            end
          end
          let(:model) { context.stop_area }

          it { is_expected.to eq('dummy') }
        end

        context "when model is a StopArea without a code 'test'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              stop_area
            end
          end
          let(:model) { context.stop_area }

          it { is_expected.to be_nil }
        end
      end
    end

    context '#apply_pattern' do
      subject { source.apply_pattern(value) }

      context "when the given value is 'dummy'" do
        let(:value) { 'dummy' }

        context 'when pattern is empty' do
          it { is_expected.to eq('dummy') }
        end

        context "when pattern is '(m+)'" do
          before { source.pattern = '(m+)' }
          it { is_expected.to eq('mm') }
        end
      end
    end
  end

  describe Macro::CreateCode::Target do
    subject(:target) { Macro::CreateCode::Target.new }

    # rubocop:disable Style/FormatStringToken
    describe '#apply_pattern' do
      subject { target.apply_pattern(model, value) }

      let(:model) { nil }
      let(:context) do
        Chouette.create do
          code_space short_name: 'public'

          line :line, registration_number: 'LINE42', codes: { 'public' => 'PUBLIC_LINE42' }
          stop_area

          referential lines: %i[line] do
            route line: :line do
              vehicle_journey
            end
          end
        end
      end

      context "when the given value is 'dummy'" do
        let(:value) { 'dummy' }

        context 'when target pattern is empty' do
          it { is_expected.to eq('dummy') }
        end

        context "when pattern is 'prefix %{value} suffix'" do
          before { target.pattern = 'prefix %{value} suffix' }
          it { is_expected.to eq('prefix dummy suffix') }
        end

        context "when pattern is '%{value//m/M}'" do
          before { target.pattern = '%{value//m/M}' }
          it { is_expected.to eq('duMMy') }
        end

        context "when pattern is '%{value//m/MM}'" do
          before { target.pattern = '%{value//m/MM}' }
          it { is_expected.to eq('duMMMMy') }
        end

        context "when pattern is '%{value//(.*)(.)/\1_\2}'" do
          before { target.pattern = '%{value//(.*)(.)/\1_\2}' }
          it { is_expected.to eq('dumm_y') }
        end

        context "when pattern is '%{line.code}'" do
          before { target.pattern = '%{line.code}' }

          context 'with Line' do
            let(:model) { context.line(:line) }
            it { is_expected.to eq('') }
          end

          context 'with StopArea' do
            let(:model) { context.stop_area }
            it { is_expected.to eq('') }
          end

          context 'with VehicleJourney' do
            let(:model) { context.vehicle_journey }
            it { is_expected.to eq('LINE42') }
          end
        end

        context "when pattern is '%{line.code:public}'" do
          before { target.pattern = '%{line.code:public}' }

          context 'with Line' do
            let(:model) { context.line(:line) }
            it { is_expected.to eq('') }
          end

          context 'with StopArea' do
            let(:model) { context.stop_area }
            it { is_expected.to eq('') }
          end

          context 'with VehicleJourney' do
            let(:model) { context.vehicle_journey }
            it { is_expected.to eq('PUBLIC_LINE42') }
          end
        end

        context "when pattern is '%{line.code:does_not_exist}'" do
          before { target.pattern = '%{line.code:does_not_exist}' }

          context 'with VehicleJourney' do
            let(:model) { context.vehicle_journey }
            it { is_expected.to eq('') }
          end
        end
      end
    end
    # rubocop:enable Style/FormatStringToken
  end
end
