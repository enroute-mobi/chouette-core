# frozen_string_literal: true

RSpec.describe Destination::GoogleCloudStorage, type: :model do
  let(:destination) do
    Destination::GoogleCloudStorage.create!(
      name: 'GoogleCloudStorage',
      secret_file: fixture_file_upload('valid_version.json'),
      project: 'some_project',
      bucket: 'some_bucket'
    )
  end

  describe '#transmit' do
    let(:context) do
      Chouette.create do
        organisation = Organisation.find_by(code: 'first')
        workgroup owner: organisation, export_types: ['Export::Gtfs'] do
          workbench organisation: organisation do
            line :first
            referential
          end
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:line) { context.line(:first) }
    let(:workgroup) { workbench.workgroup }
    let(:referential) { context.referential }
    let(:operation) { create(:aggregate, referentials: [referential], new: referential) }
    let(:export_file) { fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip') }
    let(:export) do
      Export::Gtfs.create!(
        name: 'Test',
        creator: 'test',
        referential: referential,
        workgroup: workgroup,
        workbench: workbench,
        file: export_file
      )
    end
    let(:publication) { create(:publication, parent: operation, export: export) }

    before do
      gcs_bucket_double = double('GCS bucket')
      @gcs_bucket_create_files = []
      allow(gcs_bucket_double).to receive(:create_file) do |*args|
        @gcs_bucket_create_files << args
      end
      gcs_double = double('GCS')
      @gcs_buckets = []
      allow(gcs_double).to receive(:bucket) do |*args|
        @gcs_buckets << args
        gcs_bucket_double
      end
      @gcss = []
      allow(Google::Cloud::Storage).to receive(:new) do |*args|
        @gcss << args
        gcs_double
      end
    end

    subject { destination.transmit(publication) }

    context 'when no file is attached to export' do
      let(:export_file) { nil }

      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to GCS' do
        subject
      end
    end

    context 'when file is attached to export' do
      it 'should succeed' do
        subject
        expect(destination.reports.count).to eq(1)
        expect(destination.reports.first).to be_successful
      end

      it 'should send file to GCS' do
        subject
        expect(@gcss).to match([[{ project_id: 'some_project', credentials: be_present }]])
        expect(File.read(@gcss[0][0][:credentials])).to eq(read_fixture('valid_version.json'))
        expect(@gcs_buckets).to eq([['some_bucket', { skip_lookup: true }]])
        expect(@gcs_bucket_create_files).to match([[be_present, match(/OFFRE_TRANSDEV_2017030112251\.zip\z/)]])
        expect(File.read(@gcs_bucket_create_files[0][0])).to eq(read_fixture('OFFRE_TRANSDEV_2017030112251.zip'))
      end
    end
  end
end
