# frozen_string_literal: true

RSpec.describe Policy::Import, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.permission_exceptions' do
    subject { described_class.permission_exceptions }

    it do
      is_expected.to eq(
        {
          option_flag_urgent: 'referentials.flag_urgent',
          option_update_workgroup_providers: 'imports.update_workgroup_providers'
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
    it { is_expected.to be_falsy }
  end

  describe '#option?' do
    context 'with :something' do
      subject { policy.option?(:something) }

      it { does_not_apply_strategy(Policy::Strategy::Permission) }

      it do
        expect(policy).to receive(:around_can).with(:option, :something).and_call_original
        is_expected.to be_truthy
      end

      context 'when #option_something? is defined' do
        context 'and returns true' do
          before { expect(policy).to receive(:option_something?).and_return(true) }
          it { is_expected.to be_truthy }
        end

        context 'and returns false' do
          before { expect(policy).to receive(:option_something?).and_return(false) }
          it { is_expected.to be_falsy }
        end
      end
    end
  end

  describe '#option_flag_urgent?' do
    subject { policy.option_flag_urgent? }

    it { applies_strategy(Policy::Strategy::Permission, :option_flag_urgent) }

    it do
      expect(policy).to receive(:around_can).with(:option_flag_urgent).and_call_original
      is_expected.to be_truthy
    end
  end

  describe '#option_update_workgroup_providers?' do
    subject { policy.option_update_workgroup_providers? }

    it { applies_strategy(Policy::Strategy::Permission, :option_update_workgroup_providers) }

    it do
      expect(policy).to receive(:around_can).with(:option_update_workgroup_providers).and_call_original
      is_expected.to be_truthy
    end
  end
end
