# frozen_string_literal: true

RSpec.describe Policy::ShapeProvider, type: :policy do
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '#create?' do
    subject { policy.create?(resource_class) }

    let(:resource_class) { double }

    it { applies_strategy(Policy::Strategy::Permission, :create, resource_class) }

    it { is_expected.to be_falsy }

    context 'PointOfInterestCategory' do
      let(:resource_class) { PointOfInterest::Category }
      it { is_expected.to be_truthy }
    end

    context 'PointOfInterest' do
      let(:resource_class) { PointOfInterest::Base }
      it { is_expected.to be_truthy }
    end

    context 'ServiceFacilitySet' do
      let(:resource_class) { ServiceFacilitySet }
      it { is_expected.to be_truthy }
    end

    context 'AccessibilityAssessment' do
      let(:resource_class) { AccessibilityAssessment }
      it { is_expected.to be_truthy }
    end
  end
end
