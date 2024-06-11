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

  describe '#last_aggregate' do
    let(:context) do
      Chouette.create do
        organisation = Organisation.find_by(code: 'first')
        workgroup owner: organisation do
          workbench organisation: organisation do
            referential :referential1
            referential :referential2
            referential :other_referential
          end
        end
      end
    end
    let(:workgroup) { context.workgroup }
    let(:workbench) { context.workbench }
    let(:referentials) { [context.referential(:referential1), context.referential(:referential2)] }

    let(:merge) do
      workbench.merges.create!(referentials: referentials).tap(&:merge!)
    end
    let(:aggregate) do
      workgroup.aggregates.create!(referentials: [context.referential(:other_referential), merge.new]).tap(&:aggregate!)
    end

    subject { merge.last_aggregate }

    it 'is nil when there is no aggregate' do
      is_expected.to be_nil
    end

    it 'is a successful aggregate on the output referential' do
      aggregate
      is_expected.to eq(aggregate)
    end

    it 'is nil when there is no successful aggregate' do
      aggregate.cancel!
      is_expected.to be_nil
    end

    it 'is nil when there is no aggregate on the output referential' do
      workgroup.aggregates.create!(referentials: referentials).tap(&:aggregate!)
      is_expected.to be_nil
    end

    it 'is the last aggregate' do
      aggregate
      Timecop.travel(1.second.from_now)
      new_aggregate = workgroup.aggregates.create!(referentials: [context.referential(:other_referential), merge.new])
      new_aggregate.aggregate!
      is_expected.to eq(new_aggregate)
    ensure
      Timecop.return
    end
  end
end
