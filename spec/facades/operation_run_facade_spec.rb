# frozen_string_literal: true

RSpec.describe OperationRunFacade do
  let(:workbench) { instance_double('Workbench', id: 1) }
  let(:macro_list_run) { instance_double('Macro::List::Run', id: 2, workbench: workbench) }
  let(:macro_run) { instance_double('Macro::Dummy::Run', id: 3) }
  let(:facade) { OperationRunFacade.new(macro_list_run, display_referential_links: true) }

  describe '#message_table_params' do
    it 'should have 3 columns' do
      columns, options = facade.message_table_params
      expect(columns.length).to eq(2)
    end
  end

  describe '#source_link' do
    subject { facade.source_link message }
    context 'when message has no source' do
      let(:message) { Macro::Message.new }

      it { is_expected.to be_nil }
    end
  end
end
