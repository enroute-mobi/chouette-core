RSpec.describe ImportsController, :type => :controller do

  let(:organisation){ @user.organisation }
  let(:workbench) { create :workbench, organisation: organisation }
  let(:import)    { create :import, workbench: workbench }

  context 'logged in' do
    login_user
    describe "GET index" do
      context 'on a workbench' do
        let(:request){ get :index, workbench_id: workbench.id }
        it_behaves_like 'checks current_organisation'
      end

      context 'on a workgroup' do
        let(:request){ get :index, workgroup_id: workbench.workgroup_id }
        it_behaves_like 'checks current_organisation'
      end
    end

    describe 'GET #new' do
      it 'should be successful if authorized' do
        get :new, workbench_id: workbench.id
        expect(response).to be_success
      end

      it 'should be unsuccessful unless authorized' do
        remove_permissions('imports.create', from_user: @user, save: true)
        get :new, workbench_id: workbench.id
        expect(response).not_to be_success
      end
    end

    describe "POST #create" do
      it "displays a flash message" do
        post :create, workbench_id: workbench.id,
          import: {
            name: 'Offre',
            file: fixture_file_upload('nozip.zip')
          }
      end
    end
  end

  describe 'GET #download' do
    let(:organisation){ create(:organisation) }

    it 'should be successful' do
      get :download, workbench_id: workbench.id, id: import.id, token: import.token_download
      expect(response).to be_success
      expect( response.body ).to eq(import.file.read)
    end
  end
end
