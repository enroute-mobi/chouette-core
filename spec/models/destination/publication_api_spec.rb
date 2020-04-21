
RSpec.describe Destination::PublicationApi, type: :model do
  let(:publication_api) { create :publication_api }
  let(:publication_setup) { create :publication_setup }
  let(:file){ File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json')) }

  let(:line_1) { create :line }
  let(:line_2) { create :line }

  let(:export_1) { create :netex_export, status: :successful, options: { duration: 90, line_code: line_1.id, export_type: :line }, file: file }
  let(:export_2) { create :netex_export, status: :successful, options: { duration: 90, line_code: line_2.id, export_type: :line }, file: file }
  let(:other_export_1) { create :netex_export, status: :successful, options: { duration: 90, line_code: line_1.id, export_type: :line }, file: file }
  let(:other_export_2) { create :netex_export, status: :successful, options: { duration: 90, line_code: line_2.id, export_type: :line }, file: file }
  let(:other_publication_setup) { create :publication_setup, export_type: publication_setup.export_type, export_options: publication_setup.export_options }
  let(:destination) { build :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }

  it 'should be valid' do
    expect(destination).to be_valid
  end

  context 'when another PublicationSetup of same kind already publishes to that API' do
    before do
      create :destination, type: Destination::PublicationApi, publication_setup: other_publication_setup, publication_api: publication_api
    end

    it 'should not be valid' do
      expect(destination).to_not be_valid
      expect(destination.errors[:publication_api_id]).to be_present
    end
  end

  context 'when publishing' do
    let(:publication) { create :publication, publication_setup: publication_setup, exports: [export_1, export_2] }
    let(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }

    it 'should add publications to the API' do
      expect{ destination.transmit(publication) }.to change{ publication_api.publication_api_sources.count }.by 2
      expect(PublicationApiSource.all.map(&:key)).to match_array ["netex-line-#{line_1.code}", "netex-line-#{line_2.code}"]
    end

    context 'when a publication already exists' do
      before do
        other_publication = create :publication, publication_setup: publication_setup, exports: [other_export_1, other_export_2]
        destination.transmit(other_publication)
        unrelated_publication = create :publication, exports: [create(:gtfs_export, status: :successful, file: file)]
        destination.transmit(unrelated_publication)
      end

      it 'should keep only one publication for a given export type' do
        expect{ destination.transmit(publication) }.to_not change{ publication_api.publication_api_sources.count }
      end
    end
  end
end
