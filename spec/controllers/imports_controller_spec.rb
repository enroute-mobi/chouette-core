# frozen_string_literal: true

RSpec.describe ImportsController, type: :controller do
  let(:context) do
    Chouette.create do
      # To match organisation used by login_user
      organisation = Organisation.find_by(code: 'first')
      workgroup owner: organisation do
        workbench organisation: organisation do
          referential
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:workbench) { referential.workbench }

  let(:import) do
    Import::Workbench.create!(
      name: 'Test',
      creator: 'test',
      file: fixture_file_upload('google-sample-feed.zip'),
      workbench: workbench
    )
  end

  context 'logged in' do
    login_user

    describe 'GET index' do
      let(:request) { get :index, params: { workbench_id: workbench.id } }

      it 'should be successful' do
        expect(request).to be_successful
      end
    end

    describe 'GET #new' do
      it 'should be successful if authorized' do
        get :new, params: { workbench_id: workbench.id }
        expect(response).to be_successful
      end

      it 'should be unsuccessful unless authorized' do
        remove_permissions('imports.create', from_user: @user, save: true)
        get :new, params: { workbench_id: workbench.id }
        expect(response).not_to be_successful
      end
    end

    describe 'POST #create' do
      it 'displays a flash message' do
        post :create, params: {
          workbench_id: workbench.id,
          import: {
            name: 'Offre',
            file: fixture_file_upload('nozip.zip')
          }
        }
      end
    end

    describe 'GET #show' do
      it 'should be successful' do
        get :show, params: { workbench_id: workbench.id, id: import.id }
        expect(response).to be_successful
      end

      context 'in JSON format' do
        let(:import) { create :gtfs_import, workbench: workbench }

        it 'should be successful' do
          get :show, params: { workbench_id: workbench.id, id: import.id, format: :json }
          expect(response).to be_successful
        end
      end
    end

    describe 'GET #download' do
      it 'should be successful' do
        get :download, params: { workbench_id: workbench.id, id: import.id }
        expect(response).to be_successful
        expect(response.body).to eq(import.file.read)
      end
    end

    describe 'GET #messages' do
      let(:import_resource) { create(:import_resource, import: import) }

      it 'returns 3 lines in CSV file' do
        %w[info warning error].map { |c| create(:import_message, resource: import_resource, criticity: c) }
        params = { workbench_id: workbench.id, id: import.id, import_resource_id: import_resource.id, format: :csv }
        get :messages, params: params
        expect(response.body.split("\n").count).to eq(3)
      end
    end
  end

  describe 'GET #internal_download' do
    let(:organisation) { create(:organisation) }

    it 'should be successful' do
      get :internal_download, params: { workbench_id: workbench.id, id: import.id, token: import.token_download }
      expect(response).to be_successful
      expect(response.body).to eq(import.file.read)
    end
  end
end
