require 'rails_helper'

RSpec.describe Publication, type: :model do
  it { should belong_to :publication_setup }
  it { should belong_to :parent }
  it { should have_many :exports }
  it { should validate_presence_of :publication_setup }
  it { should validate_presence_of :parent }

  let(:export_type) { 'Export::Gtfs' }
  let(:export_options) { { duration: 90, prefer_referent_stop_area: false } }
  let(:publication_setup) { create :publication_setup, export_type: export_type, export_options: export_options }
  let(:publication) { create :publication, parent: operation, publication_setup: publication_setup }
  let(:referential) { first_referential }
  let(:operation) { create :aggregate, referentials: [first_referential] }

  before(:each) do
    operation.update status: :successful
    allow(operation).to receive(:new){ referential }

    2.times do
      referential.metadatas.create line_ids: [create(:line, line_referential: referential.line_referential).id], periodes: [Time.now..1.month.from_now]
    end

    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail', result: :expected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail unexpectedly', result: :unexpected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will succeed', result: :successful
  end

  describe '#publish' do
    it 'should create a Delayed::Job' do
      expect{ publication }.to change{ Delayed::Job.count }.by 1
      expect(publication).to be_pending
    end

    context 'with a failed operation' do
      before do
        operation.status = 'failed'
      end

      it 'should fail' do
        expect(publication).to be_failed
      end
    end
  end

  describe '#run' do
    it 'should call run_export' do
      expect(publication).to receive(:run_export)
      publication.run
      expect(publication).to be_running
    end
  end

  describe '#run_export' do
    it 'should create an export' do
      expect{ publication.run_export }.to change{ Export::Gtfs.count }.by 1
      expect_any_instance_of(Export::Gtfs).to receive(:run)
      publication.run_export
      expect(publication.exports).to be_present
    end

    context 'when the export succeeds' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          obj.update status: :successful
        end
      end

      it 'should call send_to_destinations' do
        expect(publication).to receive(:send_to_destinations)
        publication.run_export
      end

      it 'should call infer_status' do
        expect(publication).to receive(:infer_status)
        publication.run_export
      end
    end

    context 'when the export raises an error' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          raise "ooops"
        end
      end

      it 'should fail' do
        expect(publication).to_not receive(:send_to_destinations)
        publication.run_export
        expect(publication).to be_failed
        expect(publication.exports).to be_present
        publication.exports.each do |export|
          expect(export).to be_persisted
        end
      end
    end

    context 'when the export fails' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          obj.update status: :failed
        end
      end

      it 'should fail' do
        expect(publication).to_not receive(:send_to_destinations)
        publication.run_export
        expect(publication).to be_failed
        expect(publication.exports).to be_present
      end
    end

    context 'With a NETEX export by line' do
      let(:export_type) { 'Export::Netex' }
      let(:export_options) { { export_type: :line, duration: 365 } }

      context 'when the export succeeds' do
        before(:each) do
          allow_any_instance_of(Export::Netex).to receive(:call_iev_callback)
        end

        it 'should create one export per lines' do
          expect(publication).to_not receive(:send_to_destinations)
          expect(publication).to_not receive(:infer_status)
          expect{ publication.run_export }.to change{ Export::Netex.count }.by 2
          publication.run
          expect(publication.exports).to be_present
          expect(publication.status).to eq 'running'
        end

        it 'should call send_to_destinations and infer_status' do
          expect(publication).to receive(:send_to_destinations).once.and_call_original
          expect(publication).to receive(:infer_status).once.and_call_original
          publication.run
          publication.exports.update_all status: :successful
          publication.exports.reload.each &:notify_parent
          expect(publication.status).to eq 'successful_with_warnings'
        end
      end

      context 'when one export fails' do
        before(:each) do
          allow_any_instance_of(Export::Netex).to receive(:call_iev_callback)
        end

        it 'should still create one export per lines' do
          expect(publication).to_not receive(:send_to_destinations)
          expect(publication).to_not receive(:infer_status)
          expect{ publication.run_export }.to change{ Export::Netex.count }.by 2
          publication.run
          expect(publication.exports).to be_present
          expect(publication.status).to eq 'running'
        end

        it 'should call send_to_destinations and infer_status' do
          expect(publication).to receive(:send_to_destinations).once.and_call_original
          expect(publication).to receive(:infer_status).once.and_call_original
          publication.run
          publication.exports.update_all status: :successful
          publication.exports.last.update status: :failed
          publication.exports.reload.each &:notify_parent
          expect(publication.status).to eq 'failed'
        end
      end
    end
  end

  describe '#send_to_destinations' do
    it 'should call each destination' do
      publication_setup.destinations.each do |destination|
        expect(destination).to receive(:transmit).with(publication).and_call_original
      end

      expect{ publication.send_to_destinations }.to change{ DestinationReport.where(publication_id: publication.id).count }.by publication_setup.destinations.count
    end
  end

  describe '#infer_status' do
    before(:each) do
      publication.send_to_destinations
    end

    context 'with a failed destination_report' do
      it 'should set status to successful_with_warnings' do
        expect{ publication.infer_status }.to change{ publication.status }.to 'successful_with_warnings'
      end
    end

    context 'with only successful destination_reports' do
      before(:each) do
        allow_any_instance_of(DestinationReport).to receive(:status){ 'successful' }
      end

      it 'should set status to successful' do
        expect{ publication.infer_status }.to change{ publication.status }.to 'successful'
      end
    end
  end
end
