RSpec.describe WorkbenchImportWorker, type: [:worker, :request] do

  let( :worker ) { described_class.new }
  let( :import ){ build_stubbed :import, token_download: download_token, file: File.open(zip_file) }

  let( :workbench ){ import.workbench }
  let( :referential ){ import.referential }
  let( :api_key ){ build_stubbed :api_key, referential: referential, token: "#{referential.id}-#{SecureRandom.hex}" }
  let( :params ){ {referential_id: referential.id, workbench_id: workbench.id} }

  # http://www.example.com/workbenches/:workbench_id/imports/:id/download
  let( :host ){ Rails.configuration.front_end_host }
  let( :path ){ download_workbench_import_path(workbench, import) }

  let( :downloaded_zip ){ double("downloaded zip") }
  let( :download_token ){ SecureRandom.urlsafe_base64 }

  let( :upload_path ) { '/api/v1/netex_imports.json' }

  let( :entry_group_streams ) do
    2.times.map{ |i| double( "entry group stream #{i}" ) }
  end
  let( :entry_groups ) do
    2.times.map do | i |
      {"entry_group_name#{i}" => entry_group_streams[i] }
    end
  end

  let( :zip_service ){ double("zip service") }

  before do
    # That should be `build_stubbed's` job, no?
    allow(Import).to receive(:find).with(import.id).and_return(import)
    allow(Api::V1::ApiKey).to receive(:from).and_return(api_key)
    allow(ZipService).to receive(:new).with(downloaded_zip).and_return zip_service
    expect(zip_service).to receive(:entry_group_streams).and_return(entry_groups)
  end


  context 'multireferential zipfile' do
    let( :zip_file ){ File.join(fixture_path, 'multiref.zip') }

    it 'downloads a zip file' do
      expect(HTTPService).to receive(:get_resource)
        .with(host: host, path: path, params: {token: download_token})
        .and_return( downloaded_zip )

      entry_groups.each do | entry_group_name, entry_group_stream |
        expect( HTTPService ).to receive(:post_resource)
          .with(host: host,
                path: upload_path,
                resource_name: 'netex_import',
                token: api_key.token,
                params: params,
                upload: {file: [entry_group_stream, 'application/zip', entry_group_name]})
      end
      worker.perform import.id

    end
  end

end
