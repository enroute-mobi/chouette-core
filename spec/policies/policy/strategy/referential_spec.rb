# frozen_string_literal: true

RSpec.describe Policy::Strategy::Referential, type: :policy_strategy do
  let(:referential_workbench) { build_stubbed(:workbench) }
  let(:current_referential_read_only) { false }
  let(:current_referential) { build_stubbed(:referential, workbench: referential_workbench) }

  before { allow(current_referential).to receive(:referential_read_only?).and_return(current_referential_read_only) }

  describe '.context_class' do
    subject { described_class.context_class }

    it { is_expected.to eq(Policy::Context::Referential) }
  end

  describe '#apply' do
    subject { strategy.apply(:action) }

    context 'when the referential is read only' do
      let(:current_referential_read_only) { true }

      context 'when the referential workbench is the same as the context workbench' do
        let(:current_workbench) { referential_workbench }
        it { is_expected.to be_falsy }
      end

      context 'when the referential workbench is not the same as the context workbench' do
        it { is_expected.to be_falsy }
      end
    end

    context 'when the referential is not read only' do
      context 'when the referential workbench is the same as the context workbench' do
        let(:current_workbench) { referential_workbench }
        it { is_expected.to be_truthy }
      end

      context 'when the referential workbench is not the same as the context workbench' do
        it { is_expected.to be_falsy }
      end
    end
  end
end
