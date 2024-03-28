# frozen_string_literal: true

RSpec.describe Policy::Source, type: :policy do
  let(:policy_context_class) { Policy::Context::User }

  describe '.permission_exceptions' do
    subject { described_class.permission_exceptions }

    it do
      is_expected.to eq(
        {
          update_workgroup_providers: 'imports.update_workgroup_providers'
        }
      )
    end
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

  describe '#retrieve?' do
    let(:policy_permission) { true }

    subject { policy.retrieve? }

    it { applies_strategy(Policy::Strategy::Permission, :retrieve) }

    it do
      expect(policy).to receive(:around_can).with(:retrieve).and_call_original
      is_expected.to be_truthy
    end
  end

  describe '#update_workgroup_providers?' do
    subject { policy.update_workgroup_providers? }

    it { applies_strategy(Policy::Strategy::Permission, :update_workgroup_providers) }

    it do
      expect(policy).to receive(:around_can).with(:update_workgroup_providers).and_call_original
      is_expected.to be_truthy
    end
  end
end
