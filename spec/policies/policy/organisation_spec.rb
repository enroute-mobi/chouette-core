# frozen_string_literal: true

RSpec.describe Policy::Organisation, type: :policy do
  let(:policy_context_class) { Policy::Context::User }

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Permission) }

    it { is_expected.to be_truthy }
  end
end
