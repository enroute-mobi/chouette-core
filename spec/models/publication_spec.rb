# frozen_string_literal: true

RSpec.describe Publication, type: :model do
  it { is_expected.to belong_to(:publication_setup).required }
  it { is_expected.to belong_to(:referential).required }
  it { is_expected.to belong_to(:parent).optional }
  it { should have_one :export }

  it { is_expected.to have_one(:workgroup) }
  it { is_expected.to have_one(:organisation) }

  context '.callback_classes' do
    subject { described_class.callback_classes }

    it { is_expected.to include(Publication::ExportStatus) }
  end

  let(:export_type) { 'Export::Setup::Gtfs' }
  let(:export_setup) { { type: export_type, scope_setup: { type: 'Export::Setup::Scope::PublishedReferential' } } }
  let(:publication_setup_priority) { 1 }
  let(:publication_setup) do
    create(:publication_setup, priority: publication_setup_priority, export_setup: export_setup)
  end
  let(:referential) { first_referential }
  let(:publication) do
    create(
      :publication,
      referential: first_referential,
      parent: operation,
      publication_setup: publication_setup,
      creator: 'test'
    )
  end
  let(:operation) { create :aggregate, referentials: [first_referential] }

  before(:each) do
    operation.update status: :successful
    allow(operation).to receive(:new) { referential }

    2.times do
      referential.metadatas.create line_ids: [create(:line, line_referential: referential.line_referential).id],
                                   periodes: [Time.now..1.month.from_now]
    end

    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail', result: :expected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will fail unexpectedly',
                                           result: :unexpected_failure
    publication_setup.destinations.create! type: 'Destination::Dummy', name: 'I will succeed', result: :successful
  end

  describe '#perform' do
    subject { publication.perform }

    it 'should create an export' do
      expect_any_instance_of(Export::Gtfs).to receive(:run)
      subject
      expect(publication.export).to be_present
    end

    context 'when publication setup has line restrictions' do
      let(:line_ids) { referential.lines.map(&:id) }

      before do
        publication_setup.export_setup.scope_setup.vehicle_journeys.included_lines = {
          type: 'Export::Setup::Scope::LineSelector::Lines',
          line_ids: line_ids
        }
      end

      it 'should create an export' do
        subject
        expect(publication.export.setup.scope_setup.vehicle_journeys.included_lines.line_ids).to eq(line_ids)
      end
    end

    context 'when the export succeeds' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |obj|
          obj.update status: :successful
        end
      end

      it 'should call send_to_destinations' do
        expect(publication).to receive(:send_to_destinations)
        subject
      end

      it 'should send notifications' do
        create(:workbench, workgroup: publication.workgroup, organisation: publication.workgroup.owner)
        publication.workgroup.owner_workbench.notification_rules.create!(
          notification_type: 'publication',
          rule_type: 'notify',
          target_type: 'external_email',
          external_email: 'user@test.ex'
        )

        expect { subject }.to change { Delayed::Job.count }.by(1)
        expect(Delayed::Job.last.payload_object.job_data['job_class']).to eq('ActionMailer::MailDeliveryJob')
        expect(Delayed::Job.last.payload_object.job_data['arguments'].first).to eq('PublicationMailer')
        expect(Delayed::Job.last.payload_object.job_data['arguments'].last['args']).to include('user@test.ex')
      end
    end

    context 'when the export raises an error' do
      before(:each) do
        allow_any_instance_of(Export::Gtfs).to receive(:export) do |_obj|
          raise 'ooops'
        end
      end

      it 'should fail' do
        expect(publication).to_not receive(:send_to_destinations)
        subject
        expect(publication.user_status).to be_failed
        expect(publication.export).to be_present
        expect(publication.export).to be_persisted
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
        subject
        expect(publication.user_status).to be_failed
        expect(publication.export).to be_present
      end
    end
  end

  describe '#send_to_destinations' do
    it 'should call each destination' do
      publication_setup.destinations.each do |destination|
        expect(destination).to receive(:transmit).with(publication).and_call_original
      end

      expect { publication.send_to_destinations }.to change {
                                                       DestinationReport.where(publication_id: publication.id).count
                                                     }.by publication_setup.destinations.count
    end
  end

  describe '#change_status' do
    subject { publication.change_status(Operation.status.done) }

    let(:export) { create(:gtfs_export) }

    before do
      publication.send_to_destinations
      allow(export).to receive(:status).and_return 'successful'
      allow(publication).to receive(:export).and_return export
    end

    context 'with a failed destination_report' do
      it 'should set status to warning' do
        expect { subject }.to change { publication.user_status }.to 'warning'
      end
    end

    context 'with only successful destination_reports' do
      before(:each) do
        allow_any_instance_of(DestinationReport).to receive(:status) { 'successful' }
      end

      it 'should set status to successful' do
        expect { subject }.to change { publication.user_status }.to 'successful'
      end
    end
  end

  describe '#concurrent_target' do
    subject { publication.concurrent_target }

    it { is_expected.to eq("publications[referential:#{first_referential.id}]") }
  end

  context '#priority' do
    subject { publication.priority }

    context 'when publication setup priority is 1' do
      it { is_expected.to eq(0) }
    end

    context 'when publication setup priority is 50' do
      let(:publication_setup_priority) { 50 }
      it { is_expected.to eq(49) }
    end
  end

  describe 'when associated Referential is destroyed' do
    it { expect { referential.destroy }.to change(publication, :exists_in_database?).from(true).to(false) }
  end

end

RSpec.describe Publication::ExportStatus do
  subject(:callback) { described_class.new(publication) }

  let(:context) do
    Chouette::Factory.create do
      referential :referential
      publication referential: :referential
    end
  end
  let(:error_uuid) { SecureRandom.uuid }
  let(:publication) { context.publication }
  let(:export_status) { 'running' }
  let(:export) { create(:gtfs_export, status: export_status) }

  before do
    publication.error_uuid = error_uuid
    allow(publication).to receive(:export).and_return(export)
  end

  describe '#after' do
    subject { callback.after }

    context 'when publication has no error_uuid' do
      let(:error_uuid) { nil }

      it { expect { subject }.not_to change(export, :status) }
    end

    context 'when publication has error_uuid' do
      let(:publication_user_status) { 'failed' }

      %w[
        new
        pending
        running
      ].each do |export_status|
        context "when export status is \"#{export_status}\"" do
          let(:export_status) { export_status }

          it do
            expect { subject }.to change(export, :status).to('failed') \
                              .and change(export, :ended_at).to(be_present)
          end
        end
      end

      context 'when export status is "successful"' do
        let(:export_status) { 'successful' }

        it { expect { subject }.not_to change(export, :status) }
      end

      context 'when there is no export' do
        let(:export) { nil }

        it { expect { subject }.not_to raise_error }
      end
    end
  end
end
