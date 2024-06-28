# frozen_string_literal: true

RSpec.describe Macro::CreateCodeFromSequence do
  it {
    is_expected.to validate_inclusion_of(:target_model)
      .in_array(%w[StopArea Line Company])
  }

  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateCodeFromSequence::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          target_model: target_model,
          code_space_id: code_space.id,
          format: format,
          sequence_id: sequence.id
        }
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create(referential: referential, workbench: workbench)
    end

    let(:context) do
      Chouette.create do
        code_space short_name: 'test'

        company :company
        company :other_company, codes: { test: 'dummy:1' }
        line :line, company: :company
        line :other_line, company: :other_company, codes: { test: 'dummy:1' }
        stop_area :stop_area
        stop_area :other_stop_area, codes: { test: 'dummy:1' }

        referential lines: %i[line other_line] do
          route line: :line, stop_areas: %i[stop_area other_stop_area]
        end
      end
    end

    let(:sequence) do
      Sequence.create(
        name: 'Regional identifiers',
        sequence_type: 'range_sequence',
        range_start: 1,
        range_end: 10,
        workbench: workbench
      )
    end

    let(:code_space) { context.code_space }
    let(:referential) { context.referential }
    let(:workbench) { context.workbench }

    let(:model_name) { model.name }
    let(:expected_message) do
      an_object_having_attributes(
        message_attributes: {
          'model_name' => model_name,
          'code_value' => code_value
        }
      )
    end

    describe '#run' do
      subject { macro_run.run }

      before { referential.switch }

      # rubocop:disable Style/FormatStringToken
      context "when format is 'dummy:%{value}'" do
        let(:format) { 'dummy:%{value}' }
        let(:code_value) { 'dummy:2' }

        context 'with StopArea' do
          let(:target_model) { 'StopArea' }
          let(:model) { context.stop_area(:stop_area) }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context 'with Line' do
          let(:target_model) { 'Line' }
          let(:model) { context.line(:line) }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end

        context 'with Company' do
          let(:target_model) { 'Company' }
          let(:model) { context.company(:company) }

          it 'should create code' do
            expect { subject }.to change { model.codes.count }.from(0).to(1)
            expect(macro_run.macro_messages).to include(expected_message)
          end
        end
      end
      # rubocop:enable Style/FormatStringToken
    end
  end
end
