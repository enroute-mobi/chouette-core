# frozen_string_literal: true

RSpec.describe Policy::DenyAll do
  subject(:policy) { described_class.instance }

  let(:resource_class) { double }

  describe '#can?' do
    subject { policy.can?(:dummy) }

    it { is_expected.to be_falsy }
  end

  describe '#update?' do
    subject { policy.update? }

    it { is_expected.to be_falsy }
  end

  describe '#create?(resource_class)' do
    subject { policy.create?(resource_class) }

    it { is_expected.to be_falsy }
  end

  describe '#something?' do
    subject { policy.something? }

    it { is_expected.to be_falsy }
  end

  describe '#something?(resource_class)' do
    subject { policy.something?(resource_class) }

    it { is_expected.to be_falsy }
  end
end
