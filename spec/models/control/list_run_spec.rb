# frozen_string_literal: true

RSpec.describe Control::List::Run do
  describe ".table_name" do
    subject { described_class.table_name }
    it { is_expected.to eq("public.control_list_runs") }
  end

  describe '#perform' do
    subject { context.control_list_run.perform }

    let(:control_list_run) { context.control_list_run }

    before do
      control_list_run.build_with_original_control_list
      subject
    end

    let(:control_messages) { Control::Message.all }

    context 'with 2 controls' do
      let(:context) do
        Chouette.create do
          line :line1
          line :line2

          referential :target, lines: %i[line1 line2]

          control_list :original_control_list do
            control criticity: 'error', target_model: 'StopArea'
            control criticity: 'error', target_model: 'Line'
          end

          control_list_run original_control_list: :original_control_list, referential: :target
        end
      end

      let(:line_control_run) { control_list_run.control_runs.detect { |mr| mr.options['target_model'] == 'Line' } }

      it 'creates a control list run with 2 control runs' do # rubocop:disable Metrics/BlockLength
        expect(control_list_run).to have_attributes(
          status: 'done',
          user_status: 'failed'
        )
        expect(control_list_run.control_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Control::Dummy::Run',
              criticity: 'error',
              options: {
                'target_model' => 'StopArea',
                'expected_result' => 'warning'
              },
              position: 1
            ),
            an_object_having_attributes(
              type: 'Control::Dummy::Run',
              criticity: 'error',
              options: {
                'target_model' => 'Line',
                'expected_result' => 'warning'
              },
              position: 2
            )
          ]
        )
        expect(control_list_run.control_context_runs).to be_empty
      end

      it 'performs all control runs and create messages' do
        expect(control_messages).to match_array(
          [
            an_object_having_attributes(
              control_run: line_control_run,
              source: context.line(:line1),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line1).name
              }
            ),
            an_object_having_attributes(
              control_run: line_control_run,
              source: context.line(:line2),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line2).name
              }
            )
          ]
        )
      end
    end

    context 'with 1 context having 2 controls' do
      let(:context) do
        c = Chouette.create do
          line :line1
          line :line2

          referential :target, lines: %i[line1 line2]

          control_list :original_control_list do
            control_context type: 'Control::Context::Lines', lines: [:line1] do
              control criticity: 'error', target_model: 'StopArea'
              control criticity: 'error', target_model: 'Line'
            end
          end

          control_list_run original_control_list: :original_control_list, referential: :target
        end
        c.control_context.update(line_ids: [c.line(:line1).id]) # meh...
        c
      end

      let(:line_control_run) do
        control_list_run.control_context_runs.first.control_runs.detect { |mr| mr.options['target_model'] == 'Line' }
      end

      it 'creates a control list run with 1 context with 2 control runs' do # rubocop:disable Metrics/BlockLength
        expect(control_list_run).to have_attributes(
          status: 'done',
          user_status: 'failed'
        )
        expect(control_list_run.control_context_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Control::Context::Lines::Run',
              options: { line_ids: [context.line(:line1).id] }
            )
          ]
        )
        expect(control_list_run.control_context_runs.first.control_runs).to match_array(
          [
            an_object_having_attributes(
              type: 'Control::Dummy::Run',
              criticity: 'error',
              options: {
                'target_model' => 'StopArea',
                'expected_result' => 'warning'
              },
              position: 1
            ),
            an_object_having_attributes(
              type: 'Control::Dummy::Run',
              criticity: 'error',
              options: {
                'target_model' => 'Line',
                'expected_result' => 'warning'
              },
              position: 2
            )
          ]
        )
      end

      it 'performs all control runs and create messages' do
        expect(control_messages).to match_array(
          [
            an_object_having_attributes(
              control_run: line_control_run,
              source: context.line(:line1),
              criticity: 'error',
              message_attributes: {
                'name' => context.line(:line1).name
              }
            )
          ]
        )
      end
    end
  end
end

RSpec.describe Control::List::Run::UserStatusFinalizer do
  subject(:finalizer) { described_class.new control_list_run }
  let(:control_list_run) { double }

  describe '#criticities' do
    subject { finalizer.criticities }

    let(:context) do
      Chouette.create { workbench { stop_area } }
    end

    let(:control_list_run) do
      attributes = {
        name: 'Test',
        original_control_list: control_list,
        creator: 'test',
        workbench: context.workbench
      }
      context.workbench.control_list_runs.create!(attributes) do |control_list_run|
        control_list_run.build_with_original_control_list
        control_list_run.control_runs.each do |control_run|
          2.times do
            control_run.control_messages.build(criticity: control_run.criticity, source: context.stop_area)
          end
        end
        control_list_run.control_context_runs.each do |control_context_run|
          control_context_run.control_runs.each do |control_run|
            2.times do
              control_run.control_messages.build(criticity: control_run.criticity, source: context.stop_area)
            end
          end
        end
      end
    end

    context 'with messages attached to control list run' do
      let(:control_list) do
        context.workbench.control_lists.create!(name: 'Test') do |control_list|
          control_list.controls << Control::Dummy.new(criticity: :error)
          control_list.controls << Control::Dummy.new(criticity: :warning)
        end
      end

      it 'returns all kind of criticities present into the control list run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end

    context 'with messages attached to context run' do
      let(:control_list) do
        context.workbench.control_lists.create!(name: 'Test') do |control_list|
          control_context = Control::Context::TransportMode.new(transport_mode: 'bus')
          control_context.controls << Control::Dummy.new(criticity: :error)
          control_context.controls << Control::Dummy.new(criticity: :warning)
          control_list.control_contexts << control_context
        end
      end

      it 'returns all kind of criticities present into the control context run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end

    context 'with messages attached to both list run and context run' do
      let(:control_list) do
        context.workbench.control_lists.create!(name: 'Test') do |control_list|
          control_list.controls << Control::Dummy.new(criticity: :warning)
          control_context = Control::Context::TransportMode.new(transport_mode: 'bus')
          control_context.controls << Control::Dummy.new(criticity: :error)
          control_list.control_contexts << control_context
        end
      end

      it 'returns all kind of criticities present both into control list run and control context run messages' do
        is_expected.to match_array(%w[error warning])
      end
    end
  end

  describe "#worst_criticity" do
    subject { finalizer.worst_criticity }

    before { allow(finalizer).to receive(:criticities).and_return(criticities) }

    [
      [ %w{warning error}, "error" ],
      [ %w{error warning}, "error" ],
      [ %w{error}, "error" ],
      [ %w{warning}, "warning" ],
      [ [], nil ],
    ].each do |criticities, expected|
      context "if criticities are #{criticities.inspect}" do
        let(:criticities) { criticities }
        it { is_expected.to eq(expected) }
      end
    end
  end

  describe "#user_status" do
    subject { finalizer.user_status }

    before { allow(finalizer).to receive(:worst_criticity).and_return(worst_criticity) }

    [
      [ "error", Operation.user_status.failed ],
      [ "warning", Operation.user_status.warning ],
      [ nil, Operation.user_status.successful ],
    ].each do |worst_criticity, expected|
      context "if worst criticity is #{worst_criticity}" do
        let(:worst_criticity) { worst_criticity }
        it { is_expected.to eq(expected) }
      end
    end
  end
end
