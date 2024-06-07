RSpec.describe Destination::PublicationApi, type: :model do
  let(:publication_api) { create :publication_api }
  let(:publication_setup) { create :publication_setup }
  let(:report) { create(:destination_report) }
  let(:error_publication_api_id) { 99_999_999 }

  let(:file) { File.open(Rails.root.join('spec/fixtures/terminated_job.json').to_s) }

  let(:line_1) { create :line }
  let(:line_2) { create :line }

  let(:gtfs_export) { create :gtfs_export, status: :successful, options: { duration: 90 }, file: file }
  let(:netex_generic_export) do
    create :netex_generic_export, status: :successful, options: { duration: 90 }, file: file
  end

  let(:export_with_line1) do
    create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_1.id] }, file: file
  end
  let(:export_with_line2) do
    create :gtfs_export, status: :successful, options: { duration: 90, line_ids: [line_2.id] }, file: file
  end

  it 'should be valid' do
    destination = build :publication_api_destination, publication_setup: publication_setup,
                                                      publication_api: publication_api
    expect(destination).to be_valid
  end

  context 'when destination contains publication_api_id but its publication_api object does not exsit' do
    it 'should not be valid' do
      destination = build :publication_api_destination, publication_setup: publication_setup,
                                                        publication_api_id: error_publication_api_id
      expect(destination).not_to be_valid
    end
  end

  context '#do_transmit' do
    let!(:publication) { create :publication, publication_setup: publication_setup, export: gtfs_export }
    let!(:destination) do
      create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api
    end
    it 'should create a publication_api_source if no publication_api_source exists' do
      expect { destination.transmit(publication) }.to change { publication_api.publication_api_sources.count }.by 1
    end

    it 'should not create a new publication_api_source if publication_api_source with same key exists' do
      create :publication_api_source, publication: publication, publication_api: publication_api, export: gtfs_export,
                                      key: 'gtfs.zip'

      expect { destination.transmit(publication) }.to change { publication_api.publication_api_sources.count }.by 0
    end

    let(:new_publication) { create :publication, :with_netex_generic, export: netex_generic_export }
    it 'should create a new publication_api_source if publication_api_source with same key does not exists' do
      create :publication_api_source, publication: publication, publication_api: publication_api, export: gtfs_export,
                                      key: 'gtfs.zip'
      expect { destination.transmit(new_publication) }.to change { publication_api.publication_api_sources.count }.by 1
    end

    context 'when destination contains publication_api_id but its publication_api object does not exsit' do
      before do
        allow(destination).to receive(:publication_api).and_return(nil)
        allow(destination).to receive(:publication_api_id).and_return(error_publication_api_id)

        destination.do_transmit(publication, report)
      end

      it 'should update error message into report' do
        expect(report.error_message).to eq(I18n.t('destinations.errors.publication_api.empty'))
      end
    end
  end

  context '#api_is_not_already_used' do
    let!(:publication) { create :publication, publication_setup: publication_setup, export: gtfs_export }
    let!(:destination) do
      create :publication_api_destination, publication_setup: publication_setup, publication_api: publication_api
    end

    it 'should return true if an existing publication setup with the same destination is saved' do
      expect(destination.api_is_not_already_used).to be_truthy
    end

    it 'should return true if a publication with different export_options type exists' do
      new_publication_setup = create :publication_setup_netex_generic, workgroup: publication_setup.workgroup
      new_destination = build :publication_api_destination, publication_setup: new_publication_setup,
                                                            publication_api: publication_api
      expect(new_destination.api_is_not_already_used).to be_truthy
    end

    it 'should return false and an error if a publication with the same export_options type exists' do
      new_publication_setup = create :publication_setup, export_options: publication_setup.export_options,
                                                         workgroup: publication_setup.workgroup
      new_destination = build :publication_api_destination, publication_setup: new_publication_setup,
                                                            publication_api: publication_api
      expect(new_destination.api_is_not_already_used).to be_falsey
      expect(new_destination.errors.messages[:publication_api_id]).to eq [I18n.t('destinations.errors.publication_api.already_used')]
    end
  end

  context '#generate_key' do
    it 'should generate for each format the good key' do
      destination = build(:publication_api_destination, publication_setup: publication_setup,
                                                        publication_api: publication_api)

      expect(destination.generate_key(nil)).to be_nil

      expect(destination.generate_key(gtfs_export)).to eq 'gtfs.zip'

      netex_export = create(:netex_generic_export)
      expect(destination.generate_key(netex_export)).to eq 'netex.zip'
    end
  end
end
