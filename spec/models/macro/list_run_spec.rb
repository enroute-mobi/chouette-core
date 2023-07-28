RSpec.describe Macro::List::Run do
  describe '.table_name' do
    subject { described_class.table_name }
    it { is_expected.to eq('public.macro_list_runs') }
  end

  describe "#perform" do
    let(:context) do
      Chouette.create do

        referential :target

        macro_list :original_macro_list do
          macro expected_result: 'error', target_model: 'StopArea'
          macro expected_result: 'error', target_model: 'Line'
        end

        macro_list_run original_macro_list: :original_macro_list, referential: :target
      end
    end

    let(:macro_list_run) { context.macro_list_run }
    let(:line) { context.referential(:target).lines.first }

    before do
      macro_list_run.build_with_original_macro_list
      context.macro_list_run.perform
    end

    let(:expected_message_line) do
      an_object_having_attributes({
        criticity: 'error',
        message_attributes: {
          'name' => line.name,
          'result' => 'error'
        }
      })
    end

    let(:macro_messages) { Macro::Message.all }

    it 'should perform all macro runs and create messages' do
      expect(macro_messages).to contain_exactly(expected_message_line)
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

    let(:macro_list) do
      context.workbench.macro_lists.create!(name: 'Test') do |macro_list|
        macro_list.macros << Macro::Dummy.new(expected_result: :error)
        macro_list.macros << Macro::Dummy.new(expected_result: :warning)
      end
    end

    let(:macro_list_run) do
      attributes = { name: 'Test', original_macro_list: macro_list, creator: 'test', workbench: context.workbench }
      source = context.stop_area

      context.workbench.macro_list_runs.create!(attributes) do |macro_list_run|
        macro_list_run.build_with_original_macro_list

        macro_list_run.macro_runs.each do |macro_run|
          2.times do
            macro_run.macro_messages.build(criticity: macro_run.expected_result, source: source)
          end
        end
      end
    end

    it 'returns all kind of criticities present into the Macro::List::Run messages' do
      is_expected.to eq(%w[error warning])
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
