# frozen_string_literal: true

RSpec.describe Macro::CreateCodeFromUuid do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateCodeFromUuid::Run do
    let(:macro_run) do
      described_class.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          target_model: target_model,
          code_space_id: code_space.id,
          format: format
        }
      )
    end

    let(:macro_list_run) do
      Macro::List::Run.create(referential: referential, workbench: workbench)
    end

    let(:context) do
      Chouette.create do
        code_space short_name: 'test'
        stop_area :first
        stop_area :second, codes: { test: 'dummy:1' }
        stop_area :last, codes: { test: 'dummy:2' }
        referential do
          route stop_areas: %i[first second last]
        end
      end
    end

    let(:format) { 'dummy:%{value}' } # rubocop:disable Style/FormatStringToken
    let(:code_space) { context.code_space }
    let(:referential) { context.referential }
    let(:workbench) { context.workbench }
    let(:model_name) { model.name }

    describe '#run' do
      subject { macro_run.run }
      before { referential.switch }
      let(:expected_message) do
        an_object_having_attributes(
          message_attributes: {
            'model_name' => model_name,
            'code_value' => match(/\Adummy:\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b\z/)
          }
        )
      end

      describe 'StopArea' do
        let(:target_model) { 'StopArea' }
        let(:model) { context.stop_area(:first) }

        it 'should create code' do
          expect { subject }.to change { model.codes.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(expected_message)
        end
      end
    end
  end
end
