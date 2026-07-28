# frozen_string_literal: true

RSpec.describe Policy::StopArea, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }
  let(:stop_area_provider) { StopAreaProvider.new }
  let(:resource) { Chouette::StopArea.new(stop_area_provider: stop_area_provider) }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::StopAreaProvider) }

    it { is_expected.to be_falsy }

    context 'DocumentMembership' do
      let(:resource_class) { ::DocumentMembership }

      it { applies_strategy(::Policy::Strategy::Permission, :create, ::DocumentMembership) }
      it { applies_strategy(::Policy::Strategy::Permission, :update) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::StopAreaProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }

    context 'when stop area provider disables manual edit' do
      before { stop_area_provider.disable_stop_area_manual_edit = true }

      it { is_expected.to be_falsy }
    end
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::StopAreaProvider) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end
end
