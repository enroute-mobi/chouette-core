# frozen_string_literal: true

RSpec.describe Policy::Control::List, type: :policy do
  describe '.permission_namespace' do
    subject { described_class.permission_namespace }
    it { is_expected.to eq('control_lists') }
  end

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'with Control::List::Run' do
      let(:resource_class) { Control::List::Run }
      it { is_expected.to be_truthy }
    end
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

    let(:policy_create_control_list_run) { true }

    before { allow(policy).to receive(:create?).with(Control::List::Run).and_return(policy_create_control_list_run) }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it do
      expect(policy).to receive(:around_can).with(:execute).and_call_original
      is_expected.to be_truthy
    end

    context 'when user cannot create control list run' do
      let(:policy_create_control_list_run) { false }
      it { is_expected.to be_falsy }
    end
  end
end
