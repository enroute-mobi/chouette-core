# frozen_string_literal: true

RSpec.describe Policy::Strategy::DocumentProvider, type: :policy_strategy do
  let(:context) do
    Chouette.create do
      user
      workbench :document_workbench do
        document_provider do
          document
        end
      end
      workbench :other_workbench
    end
  end
  let(:resource) { context.document }

  let(:current_workbench) { context.workbench(:document_workbench) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::Workbench) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the document provider workbench is the same as the context workbench' do
      it { is_expected.to be_truthy }
    end

    context 'when the document provider workbench is not the same as the context workbench' do
      let(:current_workbench) { context.workbench(:other_workbench) }
      it { is_expected.to be_falsy }
    end
  end
end
