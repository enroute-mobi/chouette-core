# frozen_string_literal: true

RSpec.describe Policy::ProcessingRule::Workbench, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.permission_namespace' do
    subject { described_class.permission_namespace }
    it { is_expected.to eq('processing_rules') }
  end

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
