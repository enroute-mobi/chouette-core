# frozen_string_literal: true

RSpec.describe Policy::PermitAll do
  subject(:policy) { Policy::PermitAll.new(resource) }

  let(:resource) { double }
  let(:resource_class) { User }

  describe '#can?' do
    subject { policy.can?(:dummy) }

    it { is_expected.to be_truthy }
  end

  describe '#update?' do
    subject { policy.update? }

    it { is_expected.to be_truthy }
  end

  describe '#create?(resource_class)' do
    subject { policy.create?(resource_class) }

    it { is_expected.to be_truthy }
  end

  describe '#something?' do
    subject { policy.something? }

    it { is_expected.to be_truthy }
  end

  describe '#something?(resource_class)' do
    subject { policy.something?(resource_class) }

    it { is_expected.to be_truthy }
  end
end
