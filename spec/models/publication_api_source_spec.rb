require 'rails_helper'

RSpec.describe PublicationApiSource, type: :model do
  it { should belong_to :publication_api }
  it { should belong_to :publication }

  let(:line) { create :line }
  let(:public_url) {"http://www.montest.com/api/v1/datas/test"}

  let(:publication_gtfs) {create :publication, :with_gtfs}
  let(:publication_idfm_netex_full) {create :publication, :with_idfm_netex_full}
  let(:publication_idfm_netex_line) {create :publication, :with_idfm_netex_line}
  let(:publication_netex_full) {create :publication, :with_netex_full}

  let(:publication_api_source) { create :publication_api_source, publication: publication_gtfs, export: nil }
  let(:publication_api_source_gtfs) { create(:publication_api_source, publication: publication_gtfs, export: create(:gtfs_export)) }
  let(:publication_api_source_idfm_netex_full) { create(:publication_api_source, publication: publication_idfm_netex_full, export: create(:idfm_netex_export_full)) }
  let(:publication_api_source_idfm_netex_line) { create(:publication_api_source, publication: publication_idfm_netex_line, export: create(:idfm_netex_export_line, export_type: 'line', line_code: line.id)) }
  let(:publication_api_source_netex_full) { create(:publication_api_source, publication: publication_netex_full, export: create(:netex_export_full)) }

  context '#generate_key' do
    it 'should generate for each format the good key' do
      expect(publication_api_source.send(:generate_key)).to be_nil

      expect(publication_api_source_gtfs.send(:generate_key)).to eq 'gtfs'

      expect(publication_api_source_idfm_netex_line.send(:generate_key)).to eq "netex-line-#{line.code}"
      expect(publication_api_source_idfm_netex_full.send(:generate_key)).to eq 'netex-full'

      expect(publication_api_source_netex_full.send(:generate_key)).to eq 'netexfull'
    end
  end

  context '#public_url' do
    it 'should generate for each format the good public url' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source.public_url).to be_nil
      expect(publication_api_source_gtfs.public_url).to eq "#{public_url}.gtfs.zip"

      expect(publication_api_source_idfm_netex_full.public_url).to eq "#{public_url}.netex-full.zip"
      expect(publication_api_source_idfm_netex_line.public_url).to eq "#{public_url}/lines/#{line.code}.netex-line.zip"

      expect(publication_api_source_netex_full.public_url).to eq "#{public_url}.netexfull.xml"
    end
  end

  context '#public_url_filename' do
    it 'should generate for each format the good public url filename' do
      allow_any_instance_of(PublicationApi).to receive(:public_url).and_return public_url

      expect(publication_api_source.public_url_filename).to be_nil
      expect(publication_api_source_gtfs.public_url_filename).to eq "test.gtfs.zip"

      expect(publication_api_source_idfm_netex_full.public_url_filename).to eq "test.netex-full.zip"
      expect(publication_api_source_idfm_netex_line.public_url_filename).to eq "#{line.code}.netex-line.zip"

      expect(publication_api_source_netex_full.public_url_filename).to eq "test.netexfull.xml"
    end
  end
end
