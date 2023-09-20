# frozen_string_literal: true

RSpec.describe Merge do
  subject(:merge) { Merge.new }

  describe '#experimental_method?' do
    subject { merge.experimental_method? }

    context 'by default' do
      before { allow(SmartEnv).to receive(:boolean).with('FORCE_MERGE_METHOD').and_return(false) }
      it { is_expected.to be_falsy }
    end

    context 'when selected merge_method is experimental' do
      before { merge.merge_method = 'experimental' }

      it { is_expected.to be_truthy }
    end

    context 'when ENV variable FORCE_MERGE_METHOD is true' do
      before { allow(SmartEnv).to receive(:boolean).with('FORCE_MERGE_METHOD').and_return(true) }

      it { is_expected.to be_truthy }
    end

    context "when Organisation has feature 'merge_with_experimental'" do
      before { merge.workbench = workbench }

      let(:workbench) { Workbench.new organisation: organisation }
      let(:organisation) { Organisation.new features: %w[merge_with_experimental] }

      it { is_expected.to be_truthy }
    end
  end
end
