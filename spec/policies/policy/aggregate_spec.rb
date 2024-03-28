# frozen_string_literal: true

RSpec.describe Policy::Aggregate, type: :policy do
  let(:policy_context_class) { Policy::Context::Workgroup }

  describe '#update?' do
    subject { policy.update? }
    it { is_expected.to be_falsy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }
    it { is_expected.to be_falsy }
  end

  describe '#rollback?' do
    subject { policy.rollback? }

    it { applies_strategy(Policy::Strategy::NotCurrentAndSuccessful) }
    it { applies_strategy(Policy::Strategy::Permission, :rollback) }

    it do
      expect(policy).to receive(:around_can).with(:rollback).and_call_original
      is_expected.to be_truthy
    end
  end
end
