# frozen_string_literal: true

RSpec.describe LegacyOperationJob do
  subject(:job) { LegacyOperationJob.new operation }

  describe '.organisation_id' do
    subject { job.organisation_id }

    let(:workbench_id) { 42 }
    let(:workbench) { Workbench.new(id: workbench_id) }

    context 'when the Operation is an Import' do
      let(:operation) { Import::Gtfs.new workbench: workbench }

      it { is_expected.to eq(workbench_id) }
    end

    context 'when the Operation is an Export' do
      let(:operation) { Export::Gtfs.new workbench: workbench }

      it { is_expected.to be_nil }
    end

    context 'when the Operation is an Publication' do
      let(:operation) { Publication.new }
      before { allow(operation).to receive(:workbench).and_return(workbench) }

      it { is_expected.to be_nil }
    end
  end
end
