# frozen_string_literal: true

RSpec.describe Policy::JourneyPattern, type: :policy do
  let(:resource) { build_stubbed(:journey_pattern) }

  describe '#update?' do
    subject { policy.update? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { applies_strategy(Policy::Strategy::Permission, :update) }

    it { is_expected.to be_truthy }
  end

  describe '#duplicate?' do
    subject { policy.duplicate? }

    it { applies_strategy(Policy::Strategy::Referential) }
    it { does_not_apply_strategy(Policy::Strategy::Permission) }

    let(:route_policy_create_journey_pattern) { true }

    before do
      dlb = double
      expect(dlb).to receive(:create?).with(Chouette::JourneyPattern).and_return(route_policy_create_journey_pattern)
      expect(Policy::Route).to(receive(:new).with(resource.route, context: policy_context).and_return(dlb))
    end

    it do
      expect(policy).to receive(:around_can).with(:duplicate).and_call_original
      is_expected.to be_truthy
    end

    context 'when a journey pattern cannot be created from a route' do
      let(:route_policy_create_journey_pattern) { false }
      it { is_expected.to eq(false) }
    end
  end
end
