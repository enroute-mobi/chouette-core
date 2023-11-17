RSpec.describe WorkbenchImportService, type: [:request, :zip] do

  let(:context) do
    Chouette.create do
      workbench do
        line objectid: "FR1:Line:C00108:"
        line objectid: "FR1:Line:C00109:"
      end
    end
  end

  let(:workbench) { context.workbench }

  let(:line_objectids) { context.lines.pluck(:objectid).to_json }

  # Required for IBOO Stif::WorbenchScopes (?)
  let!(:organisation) { workbench.organisation.update sso_attributes: {'functional_scope' => line_objectids }}

  let(:worker) { described_class.new }
  let(:workbench_import) { create :workbench_import, token_download: download_token, workbench: workbench }

  # http://www.example.com/workbenches/:workbench_id/imports/:id/internal_download
  let(:host) { Rails.configuration.rails_host }
  # FIXME See CHOUETTE-205
  let(:path) { internal_download_workbench_import_path(workbench, workbench_import) }
  let(:upload_path) { api_v1_internals_netex_imports_path(format: :json) }

  let(:downloaded_zip_data) { File.read(zip_path) }
  let(:download_token) { random_string }

  before do
    stub_request(:get, "#{ host }#{ path }?token=#{ workbench_import.token_download }").
      to_return(body: downloaded_zip_data, status: :success)
    allow(worker).to receive(:execute_post).and_return(double(status: 200))
  end

  context 'with one directory and valid datas' do
    let(:zip_path) { fixtures_path 'imports/idfm_netex/OFFRE_TRANSDEV_20170301122517.zip' }

    it 'should make the import running' do
      expect{ worker.perform(workbench_import.id) }.not_to change{ workbench_import.messages.count }
      expect( workbench_import.reload.status ).to eq('running')
    end
  end

  context 'with too many directories' do
    let(:zip_path) { fixtures_path 'imports/idfm_netex/too_many_directories.zip' }

    it 'should make the import failed and write message key several_datasets' do
      expect{ worker.perform(workbench_import.id) }.to change{ workbench_import.messages.count }.by(1)
      expect(workbench_import.messages.map(&:message_key)).to eq(%w{several_datasets})
      expect( workbench_import.reload.status ).to eq('failed')
    end
  end

  context 'with spurious directories' do
    let(:zip_path) { fixtures_path 'imports/idfm_netex/spurious.zip' }

    it 'should make the import failed and write message key spurious_zip_file' do
      worker.perform(workbench_import.id)
      expect(workbench_import.resources.flat_map(&:messages).collect(&:message_key)).to eq(%w{inconsistent_zip_file})
      expect( workbench_import.reload.status ).to eq('failed')
    end
  end

  context 'with foreign lines' do
    let(:zip_path) { fixtures_path 'imports/idfm_netex/foreign_line.zip' }

    it 'should make the import failed and write message key corrupt_zip_file' do
      worker.perform(workbench_import.id)
      expect(workbench_import.resources.flat_map(&:messages).collect(&:message_key)).to eq(%w{foreign_lines_in_referential})
      expect(workbench_import.reload.status).to eq('failed')
    end
  end

  context 'with corrupt zip file' do
    let(:downloaded_zip_data) { '' }

    it 'should make the import failed and write message key corrupt_zip_file' do
      expect{ worker.perform(workbench_import.id) }.to change{ workbench_import.messages.count }.by(1)
      expect(workbench_import.messages.map(&:message_key)).to eq(%w{corrupt_zip_file})
      expect(workbench_import.reload.status).to eq('failed')
    end

  end

end
