# frozen_string_literal: true

RSpec.describe Policy::Strategy::ShapeProvider, type: :policy_strategy do
  let(:context) do
    Chouette::Factory.create do
      workbench :workbench do
        shape_provider :shape_provider
      end
    end
  end
  let(:resource_shape_provider_workbench) { context.workbench(:workbench) }
  let(:resource_shape_provider) { context.shape_provider(:shape_provider) }
  let(:resource) { double(shape_provider: resource_shape_provider) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::Workbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the shape provider workbench is the same as the context workbench' do
      let(:current_workbench) { context.workbench(:workbench) }
      it { is_expected.to be_truthy }
    end

    context 'when the shape provider workbench is not the same as the context workbench' do
      it { is_expected.to be_falsy }
    end
  end
end
