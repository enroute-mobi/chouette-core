# frozen_string_literal: true

RSpec.describe Macro::List::Run do
  describe '.table_name' do
    subject { described_class.table_name }
    it { is_expected.to eq('public.macro_list_runs') }
  end

  describe '#perform' do
    subject { context.macro_list_run.perform }

    let(:macro_list_run) { context.macro_list_run }

    before do
      macro_list_run.build_with_original_macro_list
      subject
    end

    let(:macro_messages) { Macro::Message.all }

    context 'with 2 macros' do
      let(:context) do
        Chouette.create do
          line :line1
          line :line2

          referential :target, lines: %i[line1 line2]

          macro_list :original_macro_list do
            macro expected_result: 'error', target_model: 'StopArea'
            macro expected_result: 'error', target_model: 'Line'
          end

          macro_list_run original_macro_list: :original_macro_list, referential: :target
        end
      end

      let(:line_macro_run) { macro_list_run.macro_runs.detect { |mr| mr.options['target_model'] == 'Line' } }

      it 'creates a control list run with 1 control run' do
        expect(macro_list_run).to have_attributes(
          status: 'done',
          user_status: 'failed'
        )
        expect(macro_list_run.macro_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Macro::Dummy::Run',
              options: {
                'target_model' => 'StopArea',
                'expected_result' => 'error'
              },
              position: 1
            ),
            an_object_having_attributes(
              type: 'Macro::Dummy::Run',
              options: {
                'target_model' => 'Line',
                'expected_result' => 'error'
              },
              position: 2
            )
          ]
        )
        expect(macro_list_run.macro_context_runs).to be_empty
      end

      it 'performs all macro runs and create messages' do
        expect(macro_messages).to match_array(
          [
            an_object_having_attributes(
              macro_run: line_macro_run,
              source: context.line(:line1),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line1).name,
                'result' => 'error'
              }
            ),
            an_object_having_attributes(
              macro_run: line_macro_run,
              source: context.line(:line2),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line2).name,
                'result' => 'error'
              }
            )
          ]
        )
      end
    end

    context 'with 1 context having 2 macros' do
      let(:context) do
        Chouette.create do
          line :line1
          line :line2

          referential :target, lines: %i[line1 line2]

          macro_list :original_macro_list do
            macro_context type: 'Macro::Context::TransportMode', transport_mode: 'bus' do
              macro expected_result: 'error', target_model: 'StopArea'
              macro expected_result: 'error', target_model: 'Line'
            end
          end

          macro_list_run original_macro_list: :original_macro_list, referential: :target
        end
      end

      let(:line_macro_run) do
        macro_list_run.macro_context_runs.first.macro_runs.detect { |mr| mr.options['target_model'] == 'Line' }
      end

      it 'creates a control list run with 1 context with 1 control run' do # rubocop:disable Metrics/BlockLength
        expect(macro_list_run).to have_attributes(
          status: 'done',
          user_status: 'failed'
        )
        expect(macro_list_run.macro_context_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Macro::Context::TransportMode::Run',
              options: { transport_mode: 'bus' }
            )
          ]
        )
        expect(macro_list_run.macro_context_runs.first.macro_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Macro::Dummy::Run',
              options: {
                'target_model' => 'StopArea',
                'expected_result' => 'error'
              },
              position: 1
            ),
            an_object_having_attributes(
              type: 'Macro::Dummy::Run',
              options: {
                'target_model' => 'Line',
                'expected_result' => 'error'
              },
              position: 2
            )
          ]
        )
      end

      it 'performs all macro runs and create messages' do
        expect(macro_messages).to match_array(
          [
            an_object_having_attributes(
              macro_run: line_macro_run,
              source: context.line(:line1),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line1).name,
                'result' => 'error'
              }
            ),
            an_object_having_attributes(
              macro_run: line_macro_run,
              source: context.line(:line2),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line2).name,
                'result' => 'error'
              }
            )
          ]
        )
      end
    end
  end
end

RSpec.describe Macro::List::Run::UserStatusFinalizer do
  subject(:finalizer) { described_class.new macro_list_run }
  let(:macro_list_run) { double }

  describe '#criticities' do
    subject { finalizer.criticities }

    let(:context) do
      Chouette.create { workbench { stop_area } }
    end

    let(:macro_list_run) do
      attributes = {
        name: 'Test',
        original_macro_list: macro_list,
        creator: 'test',
        workbench: context.workbench
      }
      context.workbench.macro_list_runs.create!(attributes) do |macro_list_run|
        macro_list_run.build_with_original_macro_list
        macro_list_run.macro_runs.each do |macro_run|
          2.times do
            macro_run.macro_messages.build(criticity: macro_run.expected_result, source: context.stop_area)
          end
        end
        macro_list_run.macro_context_runs.each do |macro_context_run|
          macro_context_run.macro_runs.each do |macro_run|
            2.times do
              macro_run.macro_messages.build(criticity: macro_run.expected_result, source: context.stop_area)
            end
          end
        end
      end
    end

    context 'with messages attached to macro list run' do
      let(:macro_list) do
        context.workbench.macro_lists.create!(name: 'Test') do |macro_list|
          macro_list.macros << Macro::Dummy.new(expected_result: :error)
          macro_list.macros << Macro::Dummy.new(expected_result: :warning)
        end
      end

      it 'returns all kind of criticities present into the macro list run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end

    context 'with messages attached to context run' do
      let(:macro_list) do
        context.workbench.macro_lists.create!(name: 'Test') do |macro_list|
          macro_context = Macro::Context::TransportMode.new(transport_mode: 'bus')
          macro_context.macros << Macro::Dummy.new(expected_result: :error)
          macro_context.macros << Macro::Dummy.new(expected_result: :warning)
          macro_list.macro_contexts << macro_context
        end
      end

      it 'returns all kind of criticities present into the macro context run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end

    context 'with messages attached to both list run and context run' do
      let(:macro_list) do
        context.workbench.macro_lists.create!(name: 'Test') do |macro_list|
          macro_list.macros << Macro::Dummy.new(expected_result: :warning)
          macro_context = Macro::Context::TransportMode.new(transport_mode: 'bus')
          macro_context.macros << Macro::Dummy.new(expected_result: :error)
          macro_list.macro_contexts << macro_context
        end
      end

      it 'returns all kind of criticities present both into macro list run and macro context run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end
  end

  describe '#worst_criticity' do
    subject { finalizer.worst_criticity }

    before { allow(finalizer).to receive(:criticities).and_return(criticities) }

    [
      [%w[warning error], 'error'],
      [%w[error warning], 'error'],
      [%w[error], 'error'],
      [%w[warning], 'warning'],
      [[], nil]
    ].each do |criticities, expected|
      context "if criticities are #{criticities.inspect}" do
        let(:criticities) { criticities }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe '#user_status' do
    subject { finalizer.user_status }

    before { allow(finalizer).to receive(:worst_criticity).and_return(worst_criticity) }

    [
      ['error', Operation.user_status.failed],
      ['warning', Operation.user_status.warning],
      [nil, Operation.user_status.successful]
    ].each do |worst_criticity, expected|
      context "if worst criticity is #{worst_criticity}" do
        let(:worst_criticity) { worst_criticity }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
