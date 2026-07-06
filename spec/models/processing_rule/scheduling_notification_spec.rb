# frozen_string_literal: true

# Scheduled ProcessingRule runs (ProcessingRule::Scheduling) invoke the associated Notification
# Rules. Control/Macro runs are Operation subclasses, so the Operation::Notifier callback already
# fires when they perform; ControlMacro::Scheduled only exposes a notification_type for scheduled
# runs (a Processing without a parent Operation) so that operation-triggered runs stay silent.
RSpec.describe 'Scheduled run notifications', type: :model do
  describe Control::List::Run do
    subject(:run) { Control::List::Run.new }

    context 'when part of a scheduled processing (no parent operation)' do
      before do
        allow(run).to receive(:processing).and_return(double('processing', present?: true, operation_id: nil))
      end

      it { is_expected.to be_scheduled }
      it { expect(run.notification_type).to eq('scheduled_processing') }
    end

    context 'when triggered by an operation' do
      before do
        allow(run).to receive(:processing).and_return(double('processing', present?: true, operation_id: 42))
      end

      it { is_expected.not_to be_scheduled }
      it { expect(run.notification_type).to be_nil }
    end

    context 'when not part of any processing' do
      before { allow(run).to receive(:processing).and_return(nil) }

      it { is_expected.not_to be_scheduled }
      it { expect(run.notification_type).to be_nil }
    end
  end

  describe Macro::List::Run do
    subject(:run) { Macro::List::Run.new }

    context 'when part of a scheduled processing (no parent operation)' do
      before do
        allow(run).to receive(:processing).and_return(double('processing', present?: true, operation_id: nil))
      end

      it { is_expected.to be_scheduled }
      it { expect(run.notification_type).to eq('scheduled_processing') }
    end

    context 'when triggered by an operation' do
      before do
        allow(run).to receive(:processing).and_return(double('processing', present?: true, operation_id: 42))
      end

      it { expect(run.notification_type).to be_nil }
    end
  end

  describe NotificationRule, '.for_operation' do
    let(:context) { Chouette.create { workbench } }
    let(:workbench) { context.workbench }

    let!(:scheduled_processing_rule) do
      workbench.notification_rules.create!(
        notification_type: 'scheduled_processing', target_type: 'workbench', priority: 10, operation_statuses: []
      )
    end
    let!(:import_rule) do
      workbench.notification_rules.create!(
        notification_type: 'import', target_type: 'workbench', priority: 10, operation_statuses: []
      )
    end

    let(:operation) do
      Control::List::Run.new.tap do |run|
        allow(run).to receive(:notification_type).and_return('scheduled_processing')
      end
    end

    it 'selects the rules matching the operation notification_type' do
      expect(workbench.notification_rules.for_operation(operation)).to contain_exactly(scheduled_processing_rule)
    end
  end
end
