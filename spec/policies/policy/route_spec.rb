# frozen_string_literal: true

RSpec.describe Policy::Route, type: :policy do
  let(:resource) { build_stubbed(:route) }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }
    it { does_not_apply_strategy(Policy::Strategy::NotUsed) }

    it { is_expected.to be_falsy }

    context 'with Chouette::JourneyPattern' do
      let(:resource_class) { Chouette::JourneyPattern }
      it { is_expected.to be_truthy }
    end

    context 'with Chouette::VehicleJourney' do
      let(:resource_class) { Chouette::VehicleJourney }
      it { is_expected.to be_truthy }
    end
  end

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#destroy?' do
    subject { policy.destroy? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :destroy) }

    it { is_expected.to be_truthy }
  end

  describe '#duplicate?' do
    subject { policy.duplicate? }

    let(:line_policy_create_route) { true }

    before do
      dbl = double
      expect(dbl).to receive(:create?).with(Chouette::Route).and_return(line_policy_create_route)
      expect(Policy::Referential).to receive(:new).with(resource.referential, context: policy_context).and_return(dbl)
    end

    it { applies_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    it do
      expect(policy).to receive(:around_can).with(:duplicate).and_call_original
      is_expected.to be_truthy
    end

    context 'when a route cannot be created from a line' do
      let(:line_policy_create_route) { false }
      it { is_expected.to eq(false) }
    end
  end
end
