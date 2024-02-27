# frozen_string_literal: true

RSpec.describe Policy::Calendar, type: :policy do
  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#share?' do
    subject { policy.share? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :share) }

    it do
      expect(policy).to receive(:around_can).with(:share).and_call_original
      is_expected.to be_truthy
    end
  end
end
