# frozen_string_literal: true

RSpec.describe Policy::LineReferential, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'LineProvider' do
      let(:resource_class) { LineProvider }
      it { is_expected.to be_truthy }
    end
  end
end
