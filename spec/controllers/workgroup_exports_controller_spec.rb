# frozen_string_literal: true

RSpec.describe WorkgroupExportsController, type: :controller do
  # because of #controller_path redefinition in controller
  def controller_class_name
    'workgroup_exports'
  end

  login_user

  let(:context) do
    organisation = self.organisation
    Chouette.create do
      workgroup owner: organisation, export_types: ['Export::Gtfs'] do
        workbench organisation: organisation do
          referential
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:workgroup) { referential.workgroup }
  let(:workbench) { referential.workbench }

  let(:file) { nil }
  let(:export) do
    Export::Gtfs.create!(
      name: 'Test',
      creator: 'test',
      referential: referential,
      workgroup: workgroup,
      workbench: workbench,
      setup: { scope_setup: { type: 'Export::Setup::Scope::Referential' } },
      file: file
    )
  end

  let(:parent_params) { { workgroup_id: workgroup.id } }

  describe 'GET index' do
    let(:request) { get :index, params: parent_params }

    it 'should be successful' do
      expect(request).to be_successful
    end
  end

  describe 'GET #show' do
    it 'should be successful' do
      get :show, params: parent_params.merge({ id: export.id })
      expect(response).to be_successful
    end

    context 'in JSON format' do
      let(:export) { create :gtfs_export, workbench: workbench }

      it 'should be successful' do
        get :show, params: parent_params.merge({ id: export.id, format: :json })
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #download' do
    let(:file) { fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip') }

    it 'should be successful' do
      get :download, params: parent_params.merge({ id: export.id })
      expect(response).to be_successful
      expect(response.body).to eq(export.file.read)
    end
  end
end
