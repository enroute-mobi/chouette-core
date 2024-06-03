RSpec.describe PublicationApiSource, type: :model do
  it { should belong_to :publication_api }
  it { should belong_to :publication }

  let(:line) { create :line }
  let(:public_url) {"http://www.montest.com/api/v1/datas/test"}

  let(:publication_gtfs) {create :publication, :with_gtfs}
  let(:publication_api_source_gtfs) { create(:publication_api_source, publication: publication_gtfs, export: create(:gtfs_export), key: "gtfs.zip") }

  let(:publication_netex_generic_idfm_line) {create :publication, :with_netex_generic, key: "netex.zip"}

  context '#public_url' do
    it 'should generate for each format the good public url' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source_gtfs.public_url).to eq "#{public_url}/gtfs.zip"
    end
  end

  context '#public_url_filename' do
    it 'should generate for each format the good public url filename' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source_gtfs.public_url_filename).to eq "gtfs.zip"
    end
  end
end
