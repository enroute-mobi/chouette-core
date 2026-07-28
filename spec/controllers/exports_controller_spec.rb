# frozen_string_literal: true

RSpec.describe ExportsController, type: :controller do
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

  let(:parent_params) { { workbench_id: workbench.id } }

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

  describe 'GET #new' do
    with_permissions 'exports.create' do
      it 'should be successful if authorized' do
        get :new, params: parent_params
        expect(response).to be_successful
      end
    end

    it 'should be unsuccessful unless authorized' do
      get :new, params: parent_params
      expect(response).not_to be_successful
    end
  end

  describe 'POST #create' do
    let(:permissions) { %w[exports.create] }
    let(:params) { { name: 'foo' } }
    let(:request) { post :create, params: parent_params.merge({ export: params }) }
    it 'should create no objects' do
      expect { request }.to_not(change { Export::Gtfs.count })
    end

    context 'with all options' do
      let(:params) do
        parent_params.merge({
                              name: 'foo',
                              type: 'Export::Gtfs',
                              referential_id: current_referential.id,
                              creator: 'Test',
                              setup: { scope_setup: { type: 'Export::Setup::Scope::Referential' } }
                            })
      end

      it 'should be successful' do
        expect { request }.to change { Export::Gtfs.count }.by(1)
      end
    end

    context 'with missing options' do
      let(:params) do
        {
          referential_id: current_referential.id,
          type: 'Export::Gtfs'
        }
      end

      it 'should be unsuccessful' do
        expect { request }.to change { Export::Gtfs.count }.by(0)
      end
    end

    context 'with wrong type' do
      let(:params) do
        {
          name: 'foo',
          type: 'Export::Foo'
        }
      end

      it 'should be unsuccessful' do
        expect { request }.to raise_error ActiveRecord::SubclassNotFound
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
