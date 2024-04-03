# frozen_string_literal: true

RSpec.describe Policy::Strategy::NotCurrentAndSuccessful, type: :policy_strategy do
  let(:resource_current) { false }
  let(:resource_successful) { true }
  let(:resource) { double(current?: resource_current, successful?: resource_successful) }

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the resource is current' do
      let(:resource_current) { true }

      context 'when the resource is successful' do
        it { is_expected.to be_falsy }
      end

      context 'when the resource is not successful' do
        let(:resource_successful) { false }
        it { is_expected.to be_falsy }
      end
    end

    context 'when the resource is not current' do
      context 'when the resource is successful' do
        it { is_expected.to be_truthy }
      end

      context 'when the resource is not successful' do
        let(:resource_successful) { false }
        it { is_expected.to be_falsy }
      end
    end
  end
end
