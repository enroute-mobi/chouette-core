# frozen_string_literal: true

RSpec.describe Policy::Strategy::StopAreaProvider, type: :policy_strategy do
  let(:resource_stop_area_provider_workbench) { build_stubbed(:workbench) }
  let(:resource_stop_area_provider) do
    build_stubbed(:stop_area_provider, workbench: resource_stop_area_provider_workbench)
  end
  let(:resource) { double(stop_area_provider: resource_stop_area_provider) }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::HasWorkbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the stop area provider workbench is the same as the context workbench' do
      let(:current_workbench) { resource_stop_area_provider_workbench }
      it { is_expected.to be_truthy }
    end

    context 'when the stop area provider workbench is not the same as the context workbench' do
      it { is_expected.to be_falsy }
    end
  end
end
