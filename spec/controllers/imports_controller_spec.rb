# frozen_string_literal: true

RSpec.describe ImportsController, type: :controller do
  let(:context) do
    organisation = self.organisation
    Chouette.create do
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
      let(:permissions) { %w[imports.create] }

      it 'should be successful if authorized' do
        get :new, params: { workbench_id: workbench.id }
        expect(response).to be_successful
      end

      context 'with permission' do
        let(:permissions) { [] }

        it 'should be unsuccessful unless authorized' do
          get :new, params: { workbench_id: workbench.id }
          expect(response).not_to be_successful
        end
      end
    end

    describe 'POST #create' do
      let(:permissions) { %w[imports.create] }
      let(:request) do
        post :create, params: {
          workbench_id: workbench.id,
          import: {
            name: 'Offre',
            file: fixture_file_upload('nozip.zip')
          }
        }
      end

      it 'creates import and displays a flash message' do
        request
        new_import = Import::Base.last
        expect(new_import.name).to eq('Offre')
        expect(new_import.file).to be_present
        expect(flash['notice']).to be_present
      end

      context '#import_override_internal_identifiers' do
        it 'is false' do
          request
          expect(Import::Base.last.override_internal_identifiers).to eq(false)
        end

        with_features 'import_netex_force_override_objectid' do
          it 'is true' do
            request
            expect(Import::Base.last.override_internal_identifiers).to eq(true)
          end
        end
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

    describe 'GET #internal_download' do
      let(:organisation) { create(:organisation) }

      it 'should be successful' do
        get :internal_download, params: { workbench_id: workbench.id, id: import.id, token: import.token_download }
        expect(response).to be_successful
        expect(response.body).to eq(import.file.read)
      end
    end
  end
end
