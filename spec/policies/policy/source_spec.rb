# frozen_string_literal: true

RSpec.describe Policy::Source, type: :policy do
  let(:policy_context_class) { Policy::Context::User }

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#retrieve?' do
    let(:policy_permission) { true }

    subject { policy.retrieve? }

    it { applies_strategy(Policy::Strategy::Permission, :retrieve) }

    it do
      expect(policy).to receive(:around_can).with(:retrieve).and_call_original
      is_expected.to be_truthy
    end
  end
end
