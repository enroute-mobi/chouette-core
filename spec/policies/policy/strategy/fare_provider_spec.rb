# frozen_string_literal: true

RSpec.describe Policy::Strategy::FareProvider, type: :policy_strategy do
  let(:context) do
    Chouette::Factory.create do
      workbench :workbench do
        fare_provider :fare_provider
      end
    end
  end
  let(:resource_fare_provider_workbench) { context.workbench(:workbench) }
  let(:resource_fare_provider) { context.fare_provider(:fare_provider) }
  let(:resource) { double(fare_provider: resource_fare_provider) }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::HasWorkbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the fare provider workbench is the same as the context workbench' do
      let(:current_workbench) { resource_fare_provider_workbench }
      it { is_expected.to be_truthy }
    end

    context 'when the fare provider workbench is not the same as the context workbench' do
      it { is_expected.to be_falsy }
    end
  end
end
