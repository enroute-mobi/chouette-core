# frozen_string_literal: true

RSpec.describe Policy::Control::List, type: :policy do
  let(:resource) { Chouette::Factory.create { control_list } }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.permission_namespace' do
    subject { described_class.permission_namespace }
    it { is_expected.to eq('control_lists') }
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { applies_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#execute?' do
    subject { policy.execute? }

    let(:workbench_policy_create_control_list_run) { true }

    before do
      dbl = double
      expect(dbl).to receive(:create?).with(Control::List::Run).and_return(workbench_policy_create_control_list_run)
      expect(Policy::Workbench).to receive(:new).with(resource.workbench, context: policy_context).and_return(dbl)
    end

    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it do
      expect(policy).to receive(:around_can).with(:execute).and_call_original
      is_expected.to be_truthy
    end

    context 'when a create control list run cannot be created from a workbench' do
      let(:workbench_policy_create_control_list_run) { false }
      it { is_expected.to be_falsy }
    end
  end
end
