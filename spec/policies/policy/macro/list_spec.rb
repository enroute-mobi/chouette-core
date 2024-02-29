# frozen_string_literal: true

RSpec.describe Policy::Macro::List, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'with Macro::List::Run' do
      let(:resource_class) { Macro::List::Run }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { applies_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#execute?' do
    subject { policy.execute? }

    let(:policy_create_macro_list_run) { true }

    before { allow(policy).to receive(:create?).with(Macro::List::Run).and_return(policy_create_macro_list_run) }

    it { does_not_apply_strategy(Policy::Strategy::Permission) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it do
      expect(policy).to receive(:around_can).with(:execute).and_call_original
      is_expected.to be_truthy
    end

    context 'when user cannot create macro list run' do
      let(:policy_create_macro_list_run) { false }
      it { is_expected.to be_falsy }
    end
  end
end
