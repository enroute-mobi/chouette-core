# frozen_string_literal: true

RSpec.describe LegacyOperationJob do
  subject(:job) { LegacyOperationJob.new operation }
  let(:operation) { double }

  describe '.organisation_id' do |_variable|
    subject { job.organisation_id }

    let(:organisation_id) { 42 }
    let(:organisation) { Organisation.new(id: organisation_id) }

    context 'when the Operations is an Import' do
      let(:operation) { Import::Gtfs.new organisation: organisation }
      let(:workbench_id) { 44 }
      let(:workbench) { Workbench.new id: workbench_id }
      before { allow(operation).to receive(:workbench).and_return(workbench) }

      it { is_expected.to eq(workbench_id) }
    end

    context 'when the Operations is an Export' do
      let(:operation) { Export::Gtfs.new organisation: organisation }

      it { is_expected.to be_nil }
    end

    context 'when the Operations is an Publication' do
      let(:operation) { Publication.new }
      before { allow(operation).to receive(:organisation).and_return(organisation) }

      it { is_expected.to be_nil }
    end
  end
end
