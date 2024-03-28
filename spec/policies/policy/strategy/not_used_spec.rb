# frozen_string_literal: true

RSpec.describe Policy::Strategy::NotUsed, type: :policy_strategy do
  let(:resource_used) { false }
  let(:resource) { double(used?: resource_used) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to be_nil }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the resource is not used' do
      it { is_expected.to be_truthy }
    end

    context 'when the resource is used' do
      let(:resource_used) { true }
      it { is_expected.to be_falsy }
    end
  end
end
