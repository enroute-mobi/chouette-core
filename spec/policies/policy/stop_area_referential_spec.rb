# frozen_string_literal: true

RSpec.describe Policy::StopAreaReferential, type: :policy do
  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'StopAreaProvider' do
      let(:resource_class) { StopAreaProvider }
      it { is_expected.to be_truthy }
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
end
