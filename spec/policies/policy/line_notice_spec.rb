# frozen_string_literal: true

RSpec.describe Policy::LineNotice, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::LineProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { applies_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end
end
