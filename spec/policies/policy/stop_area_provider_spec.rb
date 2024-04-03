# frozen_string_literal: true

RSpec.describe Policy::StopAreaProvider, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'Chouette::StopArea' do
      let(:resource_class) { Chouette::StopArea }
      it { is_expected.to be_truthy }
    end

    context 'Entrance' do
      let(:resource_class) { Entrance }
      it { is_expected.to be_truthy }
    end

    context 'StopAreaRoutingConstraint' do
      let(:resource_class) { StopAreaRoutingConstraint }
      it { is_expected.to be_truthy }
    end

    context 'Chouette::ConnectionLink' do
      let(:resource_class) { Chouette::ConnectionLink }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { applies_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end
end
