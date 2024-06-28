# frozen_string_literal: true

RSpec.describe Policy::Workbench::Sharing, type: :policy do
  let(:policy_context_class) { Policy::Context::User }

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end
end
