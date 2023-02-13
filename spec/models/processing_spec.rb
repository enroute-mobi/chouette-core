# frozen_string_literal: true

RSpec.describe Processing do
  let(:context) do
    Chouette.create do
      workbench do
        referential
        control_list
        processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control_list
      end
    end
  end

  let(:control_list) { context.control_list }
  let(:control_processing_rule) { context.processing_rule(:control_processing_rule) }
  let(:import) { create :gtfs_import, workbench: context.workbench }
  let(:control_list_run) { Control::List::Run.create referential: context.referential, workbench: context.workbench }
  let(:processing) do
    Processing.new processing_rule: control_processing_rule, processed: control_list_run, operation: import, step: 'after'
  end

  context '#perform' do
    it 'should return false if Control:List:Run#user_status is failed' do
      allow(control_list_run).to receive(:perform).and_return(nil)
      control_list_run.user_status = 'failed'

      expect(processing.perform).to be_falsy
    end

    it 'should return true if Control:List:Run#user_status is successful' do
      allow(control_list_run).to receive(:perform).and_return(nil)
      control_list_run.user_status = 'successful'

      expect(processing.perform).to be_truthy
    end

    it 'should return true if Control:List:Run#user_status is warning' do
      allow(control_list_run).to receive(:perform).and_return(nil)
      control_list_run.user_status = 'warning'

      expect(processing.perform).to be_truthy
    end
  end
end
