# frozen_string_literal: true

RSpec.describe Policy::LineProvider, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { does_not_apply_strategy(Policy::Strategy::Workbench) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'Chouette::Company' do
      let(:resource_class) { Chouette::Company }
      it { is_expected.to be_truthy }
    end

    context 'Chouette::Line' do
      let(:resource_class) { Chouette::Line }
      it { is_expected.to be_truthy }
    end

    context 'Chouette::LineNotice' do
      let(:resource_class) { Chouette::LineNotice }
      it { is_expected.to be_truthy }
    end

    context 'LineRoutingConstraintZone' do
      let(:resource_class) { LineRoutingConstraintZone }
      it { is_expected.to be_truthy }
    end

    context 'Chouette::Network' do
      let(:resource_class) { Chouette::Network }
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
