# frozen_string_literal: true

RSpec.describe Policy::User, type: :policy do
  let(:resource) { build_stubbed(:user) }
  let(:policy_context_class) { Policy::Context::User }

  describe '.context_class' do
    subject { described_class.context_class(action) }

    context 'with :update' do
      let(:action) { :update }
      it { is_expected.to eq(Policy::Context::User) }
    end

    context 'with :workbench_confirm' do
      let(:action) { :workbench_confirm }
      it { is_expected.to eq(Policy::Context::User) }
    end
  end

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { does_not_apply_strategy(Policy::User::NotSelfStrategy) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'User' do
      let(:resource_class) { User }
      it { is_expected.to be_truthy }
    end

    context 'Workgroup' do
      let(:resource_class) { Workgroup }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::User::NotSelfStrategy) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::User::NotSelfStrategy) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#block?' do
    subject { policy.block? }

    it { applies_strategy(Policy::User::NotSelfStrategy) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :block) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:block).and_call_original
      is_expected.to be_truthy
    end

    context 'when the user is blocked' do
      before { resource.locked_at = Time.zone.now }
      it { is_expected.to be_falsy }
    end

    context 'with Empty context' do
      let(:policy_context_class) { Policy::Context::Empty }
      it { is_expected.to be_falsy }
    end
  end

  describe '#unblock?' do
    subject { policy.unblock? }

    before { resource.locked_at = Time.zone.now }

    it { applies_strategy(Policy::User::NotSelfStrategy) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :unblock) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:unblock).and_call_original
      is_expected.to be_truthy
    end

    context 'when the user is blocked' do
      before { resource.locked_at = nil }
      it { is_expected.to be_falsy }
    end

    context 'with Empty context' do
      let(:policy_context_class) { Policy::Context::Empty }
      it { is_expected.to be_falsy }
    end
  end

  describe '#reinvite?' do
    subject { policy.reinvite? }

    let(:policy_create_user) { true }

    before do
      allow(policy).to receive(:create?).with(User).and_return(policy_create_user)
      resource.invitation_sent_at = Time.zone.now
    end

    it { does_not_apply_strategy(Policy::User::NotSelfStrategy) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :reinvite) }

    it do
      expect(policy).to receive(:around_can).with(:reinvite).and_call_original
      is_expected.to be_truthy
    end

    context 'when ther user cannot create user' do
      let(:policy_create_user) { false }
      it { is_expected.to be_falsy }
    end

    context 'when the user is not invited' do
      before { resource.invitation_sent_at = nil }
      it { is_expected.to be_falsy }
    end
  end

  describe '#reset_password?' do
    subject { policy.reset_password? }

    before { resource.confirmed_at = Time.zone.now }

    it { applies_strategy(Policy::User::NotSelfStrategy) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :reset_password) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it do
      allow(policy).to receive(:around_can).and_call_original
      expect(policy).to receive(:around_can).with(:reset_password).and_call_original
      is_expected.to be_truthy
    end

    context 'when the user is not confirmed' do
      before { resource.confirmed_at = nil }
      it { is_expected.to be_falsy }
    end

    context 'with Empty context' do
      let(:policy_context_class) { Policy::Context::Empty }
      it { is_expected.to be_falsy }
    end
  end

  describe '#workbench_confirm?' do
    subject { policy.workbench_confirm?(double) }

    let(:policy_permission) { true }

    before do
      allow(policy_context).to receive(:permission?).with('workbenches.confirm').and_return(policy_permission)
    end

    it { does_not_apply_strategy(Policy::User::NotSelfStrategy) }
    it { does_not_apply_strategy(Policy::Strategy::Permission, :workbench_confirm) }

    it do
      expect(policy).to receive(:around_can).with(:workbench_confirm).and_call_original
      is_expected.to be_truthy
    end

    context 'when the user cannot confirm workbenches' do
      let(:policy_permission) { false }
      it { is_expected.to be_falsy }
    end
  end
end

RSpec.describe Policy::User::NotSelfStrategy, type: :policy_strategy do
  let(:resource) { build_stubbed(:user) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::User) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the user and the context user are the same' do
      let(:current_user) { resource }
      it { is_expected.to be_falsy }
    end

    context 'when the user and the context user are different' do
      it { is_expected.to be_truthy }
    end
  end
end
