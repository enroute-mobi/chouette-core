# frozen_string_literal: true

RSpec.describe Policy::Strategy::LineProvider, type: :policy_strategy do
  let(:resource_line_provider_workbench) { build_stubbed(:workbench) }
  let(:resource_line_provider) { build_stubbed(:line_provider, workbench: resource_line_provider_workbench) }
  let(:resource) { double(line_provider: resource_line_provider) }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::HasWorkbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the line provider workbench is the same as the context workbench' do
      let(:current_workbench) { resource_line_provider_workbench }
      it { is_expected.to be_truthy }
    end

    context 'when the line provider workbench is not the same as the context workbench' do
      it { is_expected.to be_falsy }
    end
  end
end
