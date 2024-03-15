# frozen_string_literal: true

RSpec.describe Policy::JourneyPatternCollection, type: :policy do
  describe '.permission_namespace' do
    subject { described_class.permission_namespace }
    it { is_expected.to eq('journey_patterns') }
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end
end
