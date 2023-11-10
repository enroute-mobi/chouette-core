RSpec.describe WorkbenchImportService, type: [:request, :zip] do

  def self.expect_upload_with *entry_names, &blk
    let(:expected_upload_names){ Set.new(entry_names.flatten) }

    it "uploads the following entries: #{entry_names.flatten.inspect}" do
      allow( HTTPService ).to receive(:post_resource)
        .with(host: host, path: upload_path, params: anything, token: Rails.application.secrets.api_token) { |params|
        name =  params[:params][:netex_import][:name]
        raise RuntimeError, "unexpected upload of entry #{name}" unless expected_upload_names.delete?(name)
        OpenStruct.new(status: 201)
      }
      instance_eval(&blk)
      expect( expected_upload_names ).not_to be_empty, "the following expected uploads were not executed: #{expected_upload_names.to_a.inspect}"
    end
  end

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
  let!( :organisation) { workbench.organisation.update sso_attributes: {'functional_scope' => line_objectids }}

  let(:worker ) { described_class.new }
  let(:workbench_import) { create :workbench_import, token_download: download_token, workbench: workbench }

  # http://www.example.com/workbenches/:workbench_id/imports/:id/internal_download
  let(:host) { Rails.configuration.rails_host }
  # FIXME See CHOUETTE-205
  let(:path) { internal_download_workbench_import_path(workbench, workbench_import) }
  let(:upload_path) { api_v1_internals_netex_imports_path(format: :json) }

  let(:downloaded_zip_archive) { make_zip_from_tree zip_data_dir }
  let(:downloaded_zip_data) { downloaded_zip_archive.data }
  let(:download_token) { random_string }

  before do
    stub_request(:get, "#{ host }#{ path }?token=#{ workbench_import.token_download }").
      to_return(body: downloaded_zip_data, status: :success)
  end

  context 'correct workbench_import' do
    let(:zip_data_dir) { fixtures_path 'two_referentials_ok' }

    expect_upload_with %w{ OFFRE_TRANSDEV_20170301122517 OFFRE_TRANSDEV_20170301122519 } do
      expect{ worker.perform( workbench_import.id ) }.to change{ workbench_import.messages.count }
      expect( workbench_import.reload.attributes.values_at(*%w{current_step total_steps}) )
        .to eq([0, 0])
      expect( workbench_import.reload.status ).to eq('failed')
    end

  end

  # FIXME Messages structure has changed. The test process must be refactored

  # context 'correct but spurious directories' do
  #   let(:zip_data_dir) { fixtures_path 'extra_file_nok' }

  #   expect_upload_with [] do
  #     expect{ worker.perform( workbench_import.id ) }.to change{ workbench_import.messages.count }.by(1)
  #     expect( workbench_import.reload.attributes.values_at(*%w{current_step total_steps}) )
  #       .to eq([0, 0])
  #     expect( workbench_import.messages.last.message_key ).to eq('inconsistent_zip_file')
  #     expect( workbench_import.reload.status ).to eq('running')
  #   end
  # end

  # context 'foreign lines' do
  #   let(:zip_data_dir) { fixtures_path 'some_foreign_mixed' }

  #   expect_upload_with %w{ OFFRE_TRANSDEV_20170301122517 OFFRE_TRANSDEV_20170301122519 } do
  #     expect{ worker.perform( workbench_import.id ) }.to change{ workbench_import.messages.count }.by(1)
  #     expect( workbench_import.reload.attributes.values_at(*%w{current_step total_steps}) )
  #       .to eq([2, 2])
  #     expect( workbench_import.messages.last.message_key ).to eq('foreign_lines_in_referential')
  #     expect( workbench_import.reload.status ).to eq('running')
  #   end

  # end

  # context 'foreign and spurious' do
  #   let(:zip_data_dir) { fixtures_path 'foreign_and_spurious' }

  #   expect_upload_with %w{ OFFRE_TRANSDEV_20170301122517 OFFRE_TRANSDEV_20170301122519 } do
  #     expect{ worker.perform( workbench_import.id ) }.to change{ workbench_import.messages.count }.by(2)
  #     expect( workbench_import.reload.attributes.values_at(*%w{current_step total_steps}) )
  #       .to eq([2, 2])
  #     expect( workbench_import.messages.last(2).map(&:message_key).sort )
  #       .to eq(%w{foreign_lines_in_referential inconsistent_zip_file})
  #     expect( workbench_import.reload.status ).to eq('running')
  #   end
  # end

  # context 'corrupt zip file' do
  #   let(:downloaded_zip_archive) { OpenStruct.new(data: '') }

  #   it 'will not upload anything' do
  #     expect(HTTPService).not_to receive(:post_resource)
  #     expect{ worker.perform( workbench_import.id ) }.to change{ workbench_import.messages.count }.by(1)
  #     expect( workbench_import.messages.last.message_key ).to eq('corrupt_zip_file')
  #     expect( workbench_import.reload.status ).to eq('failed')
  #   end

  # end

end
