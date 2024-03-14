# frozen_string_literal: true

RSpec.describe Policy::Fare::Provider, type: :policy do
  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'Fare::Zone' do
      let(:resource_class) { Fare::Zone }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Permission, :update) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Permission, :destroy) }
    it { applies_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_truthy }
  end
end
