# frozen_string_literal: true

RSpec.describe Policy::LineReferential, type: :policy do
  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'Chouette::Company' do
      let(:resource_class) { Chouette::Company }
      it { is_expected.to be_truthy }
    end

    context 'LineProvider' do
      let(:resource_class) { LineProvider }
      it { is_expected.to be_truthy }
    end

    context 'Chouette::Line' do
      let(:resource_class) { Chouette::Line }
      it { is_expected.to be_truthy }
    end

    context 'LineRoutingConstraintZone' do
      let(:resource_class) { LineRoutingConstraintZone }
      it { is_expected.to be_truthy }
    end
  end
end
