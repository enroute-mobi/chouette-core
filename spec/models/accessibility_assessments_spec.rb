# frozen_string_literal: true

RSpec.describe AccessibilityAssessment do
  subject {accessibility_assessment.send attribute}

  let(:context) do
    Chouette.create do
      accessibility_assessment
    end
  end

  subject(:accessibility_assessment) { context.accessibility_assessment }

  describe '#uuid' do
    let(:attribute) { :uuid }

    it { is_expected.to be_present }
  end

  describe '#name' do
    let(:attribute) { :name }

    it { is_expected.to be_present }
  end

  describe '#mobility_impaired_accessibility' do
    let(:attribute) { :mobility_impaired_accessibility }

    it { is_expected.to be_present }
  end

  describe '#shape_referential' do
    let(:attribute) { :shape_referential }

    it { is_expected.to be_present }
  end
end
