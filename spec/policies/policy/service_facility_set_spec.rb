# frozen_string_literal: true

RSpec.describe Policy::ServiceFacilitySet, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

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
end
