# frozen_string_literal: true

RSpec.describe Policy::Strategy::Workbench, type: :policy_strategy do
  let(:resource_workbench) { build_stubbed(:workbench) }
  let(:resource) { double(workbench: resource_workbench) }
  let(:policy_context_class) { Policy::Context::Workbench }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::HasWorkbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the resource workbench is the same as the context workbench' do
      let(:current_workbench) { resource_workbench }
      it { is_expected.to be_truthy }
    end

    context 'when the resource workbench is not the same as the context workbench' do
      it { is_expected.to be_falsy }
    end
  end
end
