# frozen_string_literal: true

RSpec.describe OperationRunFacade do
  let(:context) do
    Chouette.create do
      workbench do
        line
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:line) { context.line }

  describe '#message_table_params' do
    context 'for Macro::List::Run' do
      let(:macro_list_run) { Macro::List::Run.create workbench: context.workbench }
      let(:facade) { OperationRunFacade.new(macro_list_run, workbench, display_referential_links: true) }

      it 'should display 3 columns' do
        columns, options = facade.message_table_params
        expect(columns.length).to eq(3)
      end
    end

    context 'for Control::List::Run' do
      let(:control_list_run) { Control::List::Run.create workbench: context.workbench }
      let(:facade) { OperationRunFacade.new(control_list_run, workbench, display_referential_links: true) }

      it 'should display 2 columns' do
        columns, options = facade.message_table_params
        expect(columns.length).to eq(2)
      end
    end
  end

  describe '#source_link' do
    subject { facade.source_link message }
    let(:macro_list_run) { Macro::List::Run.create workbench: context.workbench }
    let(:macro_run) do
      Macro::Dummy::Run.create(
        macro_list_run: macro_list_run,
        position: 0,
        options: {
          expected_result: 'error',
          target_model: 'Line'
        }
      )
    end

    context 'when message has no source' do
      let(:message) { Macro::Message.new source: nil, macro_run: macro_run }
      let(:facade) { OperationRunFacade.new(macro_list_run, workbench, display_referential_links: true) }

      it { is_expected.to be_nil }
    end

    context 'when facade should not display_referential_links' do
      let(:message) { Macro::Message.new source: line, macro_run: macro_run }
      let(:facade) { OperationRunFacade.new(macro_list_run, workbench, display_referential_links: false) }

      it { is_expected.to be_nil }
    end

    context 'when message has a source and facade display_referential_links' do
      let(:message) { Macro::Message.new source: line, macro_run: macro_run }
      let(:facade) { OperationRunFacade.new(macro_list_run, workbench, display_referential_links: true) }

      it { is_expected.to eq("/workbenches/#{workbench.id}/line_referential/lines/#{line.id}") }
    end
  end
end
