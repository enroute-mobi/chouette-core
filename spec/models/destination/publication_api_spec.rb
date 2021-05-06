
RSpec.describe Destination::PublicationApi, type: :model do
  let(:publication_api) { create :publication_api }
  let(:publication_setup) { create :publication_setup }
  let(:publication_setup_with_line) { create :publication_setup, publish_per_line: true }
  let(:file){ File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json')) }

  let(:line_1) { create :line }
  let(:line_2) { create :line }

  let(:export_1) { create :gtfs_export, status: :successful, options: { duration: 90 }, file: file }
  let(:export_2) { create :gtfs_export, status: :successful, options: { duration: 90}, file: file }

  let(:export_with_line1) { create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_1.id] }, file: file }
  let(:export_with_line2) { create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_2.id] }, file: file }

  it 'should be valid' do
    destination = build :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api
    expect(destination).to be_valid
  end

  context 'when another PublicationSetup of same kind already publishes to that API' do
    let(:other_publication_setup) { create :publication_setup, export_type: publication_setup.export_type, export_options: publication_setup.export_options }
    let!(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }
    let(:new_destination) { build :publication_api_destination, publication_setup: other_publication_setup, publication_api: publication_api }

    it 'should not be valid' do
      expect(new_destination).to_not be_valid
    end
  end

  context 'when publish for the first time' do
    let(:publication) { create :publication, publication_setup: publication_setup, exports: [export_1] }
    let(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }

    it 'should add publications to the API' do
      expect{ destination.transmit(publication) }.to change{ publication_api.publication_api_sources.count }.by 1
    end
  end

  context 'when publish twice' do
    let(:publication) { create :publication, publication_setup: publication_setup, exports: [export_1] }
    let!(:publication_api_source) { create :publication_api_source, publication: publication, publication_api: publication_api, export: export_1 }
    let(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }
    let(:other_publication) { create :publication, publication_setup: publication_setup, exports: [export_2] }

    it 'should keep only the last publication for a given export type' do
      expect{ destination.transmit(other_publication) }.to_not change{ publication_api.publication_api_sources.count }
    end
  end

  context '#generate_key' do
    it 'should generate for each format the good key' do
      destination = build(:publication_api_destination, publication_setup: publication_setup, publication_api: publication_api)

      expect(destination.generate_key(nil)).to be_nil

      expect(destination.generate_key(export_1)).to eq 'gtfs.zip'

      netex_export = create(:netex_generic_export)
      expect(destination.generate_key(netex_export)).to eq 'netex.zip'

      netex_idfm_full_export = create(:netex_export)
      expect(destination.generate_key(netex_idfm_full_export)).to eq 'netex-full.zip'

      publication_setup_gtfs_line = create(:publication_setup_gtfs, publish_per_line: true, export_options: { duration: 200, line_ids: [line_1.id] } )
      destination = build(:publication_api_destination, publication_setup: publication_setup_gtfs_line, publication_api: publication_api)
      expect(destination.generate_key(export_with_line1)).to eq "lines/#{line_1.registration_number}-gtfs.zip"

    end
  end

end
