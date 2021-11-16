RSpec.describe Destination::PublicationApi, type: :model do
  let(:publication_api) { create :publication_api }
  let(:publication_setup) { create :publication_setup }
  let(:file){ File.open(File.join(Rails.root, 'spec', 'fixtures', 'terminated_job.json')) }

  let(:line_1) { create :line }
  let(:line_2) { create :line }

  let(:gtfs_export) { create :gtfs_export, status: :successful, options: { duration: 90 }, file: file }
  let(:netex_generic_export) { create :netex_generic_export, status: :successful, options: { duration: 90 }, file: file }

  let(:export_with_line1) { create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_1.id] }, file: file }
  let(:export_with_line2) { create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_2.id] }, file: file }

  it 'should be valid' do
    destination = build :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api
    expect(destination).to be_valid
  end


  context '#do_transmit' do

    let!(:publication) { create :publication, publication_setup: publication_setup, exports: [gtfs_export] }
    let!(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }
    it 'should create a publication_api_source if no publication_api_source exists' do
      expect{ destination.transmit(publication) }.to change{ publication_api.publication_api_sources.count }.by 1
    end

    it 'should not create a new publication_api_source if publication_api_source with same key exists' do
      create :publication_api_source, publication: publication, publication_api: publication_api, export: gtfs_export, key: "gtfs.zip"

      expect{ destination.transmit(publication) }.to change{ publication_api.publication_api_sources.count }.by 0
    end

    let(:new_publication) { create :publication, :with_netex_generic, exports: [netex_generic_export]}
    it 'should create a new publication_api_source if publication_api_source with same key does not exists' do
      create :publication_api_source, publication: publication, publication_api: publication_api, export: gtfs_export, key: "gtfs.zip"
      expect{ destination.transmit(new_publication) }.to change{ publication_api.publication_api_sources.count }.by 1
    end

  end

  context '#api_is_not_already_used' do

    let!(:publication) { create :publication, publication_setup: publication_setup, exports: [gtfs_export] }
    let!(:destination) { create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api }

    it 'should return true if an existing publication setup with the same destination is saved' do
      expect( destination.api_is_not_already_used ).to be_truthy
    end

    it 'should return true if a publication with different export_options type exists' do
      new_publication_setup = create :publication_setup_netex_generic, workgroup: publication_setup.workgroup
      new_destination = build :publication_api_destination, publication_setup: new_publication_setup, publication_api: publication_api
      expect( new_destination.api_is_not_already_used ).to be_truthy
    end

    it 'should return true if a publication with same export_options type but different published_per_line value exists' do
      new_publication_setup = create :publication_setup, export_options: publication_setup.export_options, publish_per_line: true, workgroup: publication_setup.workgroup
      new_destination = build :publication_api_destination, publication_setup: new_publication_setup, publication_api: publication_api
      expect( new_destination.api_is_not_already_used ).to be_truthy
    end

    it 'should return false and an error if a publication with the same export_options type exists' do
      new_publication_setup = create :publication_setup, export_options: publication_setup.export_options, workgroup: publication_setup.workgroup
      new_destination = build :publication_api_destination, publication_setup: new_publication_setup, publication_api: publication_api
      expect( new_destination.api_is_not_already_used ).to be_falsey
      expect(new_destination.errors.messages[:publication_api_id]).to eq [I18n.t('destinations.errors.publication_api.already_used')]
    end

  end

  context '#generate_key' do
    it 'should generate for each format the good key' do
      destination = build(:publication_api_destination, publication_setup: publication_setup, publication_api: publication_api)

      expect(destination.generate_key(nil)).to be_nil

      expect(destination.generate_key(gtfs_export)).to eq 'gtfs.zip'

      netex_export = create(:netex_generic_export)
      expect(destination.generate_key(netex_export)).to eq 'netex.zip'

      netex_idfm_full_export = create(:netex_export)
      expect(destination.generate_key(netex_idfm_full_export)).to eq 'netex.zip'

      publication_setup_gtfs_line = create(:publication_setup_gtfs, publish_per_line: true, export_options: { type: "Export::Gtfs", line_ids: [line_1.id] } )
      destination = build(:publication_api_destination, publication_setup: publication_setup_gtfs_line, publication_api: publication_api)
      expect(destination.generate_key(export_with_line1)).to eq "lines/#{line_1.registration_number}-gtfs.zip"

    end
  end

end
