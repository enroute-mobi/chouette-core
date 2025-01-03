# frozen_string_literal: true

RSpec.describe PublicationApiSource, type: :model do
  let(:context) do
    Chouette.create do
      publication_api
      referential :referential
      publication referential: :referential
    end
  end
  let(:publication_api) { context.publication_api }
  let(:publication) { context.publication }
  let(:publication_api_source_gtfs) do
    publication_api.publication_api_sources.create!(
      publication: publication,
      export: create(:gtfs_export),
      key: 'gtfs.zip'
    )
  end

  it { should belong_to :publication_api }
  it { should belong_to :publication }

  context '#public_url' do
    it 'should generate for each format the good public url' do
      expect(publication_api_source_gtfs.public_url).to eq "#{publication_api.public_url}/gtfs.zip"
    end
  end

  context '#public_url_filename' do
    it 'should generate for each format the good public url filename' do
      expect(publication_api_source_gtfs.public_url_filename).to eq "gtfs.zip"
    end
  end
end
