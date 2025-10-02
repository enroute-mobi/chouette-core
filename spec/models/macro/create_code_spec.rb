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
    let(:macro_list) { Macro::List.create!(name: 'Macro List', workbench: context.workbench) }
    let(:macro_list_run_referential) { nil }
    let(:macro_list_run) do
      Macro::List::Run.create!(
        name: 'Create code',
        creator: 'user',
        original_macro_list: macro_list,
        workbench: context.workbench,
        referential: macro_list_run_referential
      )
    end
    let(:macro_run) do
      Macro::CreateCode::Run.create(
        target_model: target_model,
        source_attribute: source_attribute,
        target_code_space: 'test',
        macro_list_run: macro_list_run,
        position: 0
      ).tap do |run|
        allow(run).to receive(:workbench).and_return(context.workbench)
      end
    end

    describe '#run' do
      subject { macro_run.run }

      before { macro_list_run_referential&.switch }

      context "when the macro has target_model 'StopArea'" do
        let(:target_model) { 'StopArea' }
        let(:stop_area) { context.stop_area }

        context "source_attribute 'registration_number' and target_code_space 'test'" do
          let(:source_attribute) { 'registration_number' }

          context "when a StopArea exists with a registration_number 'dummy'" do
            let(:context) do
              Chouette.create do
                code_space short_name: 'test'
                stop_area registration_number: 'dummy'
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
              end
            end

            it "doesn't create a code" do
              expect { subject }.to_not(change { stop_area.reload.codes.count })
            end
          end
        end
      end

      context "when the macro has target_model 'Line', source_attribute 'number' and target_code_space 'test'" do
        let(:target_model) { 'Line' }
        let(:source_attribute) { 'number' }

        let(:line) { context.line }

        context "when a Line exists with a number 'dummy'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              line number: 'dummy'
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
        let(:target_model) { 'VehicleJourney' }
        let(:source_attribute) { 'published_journey_identifier' }
        let(:macro_list_run_referential) { context.referential }

        let(:vehicle_journey) { context.vehicle_journey }

        context "when a VehicleJourney exists with a published_journey_identifier 'dummy'" do
          let(:context) do
            Chouette.create do
              code_space short_name: 'test'
              referential do
                vehicle_journey published_journey_identifier: 'dummy'
              end
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
                referential do
                  vehicle_journey published_journey_identifier: 'dummy', codes: { test: 'unchanged' }
                end
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
                referential do
                  vehicle_journey published_journey_identifier: 'dummy', codes: { other_test: 'unchanged' }
                end
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
              referential do
                vehicle_journey published_journey_identifier: nil
              end
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
    subject(:target) { Macro::CreateCode::Target.new(pattern) }

    let(:pattern) { '' }

    # rubocop:disable Style/FormatStringToken
    describe '#value' do
      subject { target.value(model, value) }

      let(:line_context) do
        Chouette.create do
          code_space :public, short_name: 'public'
          code_space :test

          line :line, registration_number: 'LINE42', codes: { 'public' => 'PUBLIC_LINE42' }
        end
      end
      let(:stop_area_context) do
        Chouette.create do
          code_space :public, short_name: 'public'
          code_space :test

          stop_area :stop_area
        end
      end
      let(:vehicle_journey_context) do
        Chouette.create do
          code_space :public, short_name: 'public'
          code_space :test

          line :line, registration_number: 'LINE42', codes: { 'public' => 'PUBLIC_LINE42' }

          referential lines: %i[line] do
            route line: :line do
              vehicle_journey :vehicle_journey
            end
          end
        end
      end
      let(:journey_pattern_context) do
        Chouette.create do
          code_space :public, short_name: 'public'
          code_space :test

          shape :shape, codes: { 'public' => 'PUBLIC_SHAPE42' }

          journey_pattern :journey_pattern, shape: :shape
        end
      end
      let(:referential) { context&.referential rescue nil } # rubocop:disable Style/RescueModifier
      let(:code_space) { context&.code_space(:test) }
      let(:context_model) { nil }
      let(:context) { context_model ? send(:"#{context_model}_context") : nil }
      let(:context_record) { context_model ? context.send(context_model, context_model) : nil }
      let(:model) do
        if context_record
          Macro::CreateCodeFromUuid::Run::RequestBuilder.new(
            context.workgroup,
            context_record.class.all,
            code_space,
            target.format
          ).run.where(context_record.class.quoted_table_name => { id: context_record.id }).first
        else
          nil
        end
      end

      before { referential&.switch }

      context "when the given value is 'dummy'" do
        let(:value) { 'dummy' }

        context 'when target pattern is empty' do
          it { is_expected.to eq('dummy') }
        end

        context "when pattern is 'prefix %{value} suffix'" do
          let(:pattern) { 'prefix %{value} suffix' }
          it { is_expected.to eq('prefix dummy suffix') }
        end

        context "when pattern is '%{value//m/M}'" do
          let(:pattern) { '%{value//m/M}' }
          it { is_expected.to eq('duMMy') }
        end

        context "when pattern is '%{value//m/MM}'" do
          let(:pattern) { '%{value//m/MM}' }
          it { is_expected.to eq('duMMMMy') }
        end

        context "when pattern is '%{value//(.*)(.)/\1_\2}'" do
          let(:pattern) { '%{value//(.*)(.)/\1_\2}' }
          it { is_expected.to eq('dumm_y') }
        end

        context "when pattern is '%{line.code}'" do
          let(:pattern) { '%{line.code}' }

          context 'with Line' do
            let(:context_model) { :line }
            it { is_expected.to eq('') }
          end

          context 'with StopArea' do
            let(:context_model) { :stop_area }
            it { is_expected.to eq('') }
          end

          context 'with VehicleJourney' do
            let(:context_model) { :vehicle_journey }
            it { is_expected.to eq('LINE42') }
          end
        end

        context "when pattern is '%{line.code:public}'" do
          let(:pattern) { '%{line.code:public}' }

          context 'with Line' do
            let(:context_model) { :line }
            it { is_expected.to eq('') }
          end

          context 'with StopArea' do
            let(:context_model) { :stop_area }
            it { is_expected.to eq('') }
          end

          context 'with VehicleJourney' do
            let(:context_model) { :vehicle_journey }
            it { is_expected.to eq('PUBLIC_LINE42') }
          end
        end

        context "when pattern is '%{line.code:does_not_exist}'" do
          let(:pattern) { '%{line.code:does_not_exist}' }

          context 'with VehicleJourney' do
            let(:context_model) { :vehicle_journey }
            it { is_expected.to eq('') }
          end
        end

        context "when pattern is '%{shape.code:public}'" do
          let(:pattern) { '%{shape.code:public}' }

          context 'with Line' do
            let(:context_model) { :line }
            it { is_expected.to eq('') }
          end

          context 'with JourneyPattern' do
            let(:context_model) { :journey_pattern }
            it { is_expected.to eq('PUBLIC_SHAPE42') }
          end
        end

        context "when pattern is '%{shape.code:does_not_exist}'" do
          let(:pattern) { '%{shape.code:does_not_exist}' }

          context 'with JourneyPattern' do
            let(:context_model) { :journey_pattern }
            it { is_expected.to eq('') }
          end
        end
      end
    end
    # rubocop:enable Style/FormatStringToken
  end
end
