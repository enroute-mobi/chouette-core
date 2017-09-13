RSpec.describe ImportsController, :type => :controller do
  login_user

  let(:workbench) { create :workbench }
  let(:import)    { create :import, workbench: workbench }

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

  describe 'GET #download' do
    it 'should be successful' do
      get :download, workbench_id: workbench.id, id: import.id, token: import.token_download
      expect(response).to be_success
      expect( response.body ).to eq(import.file.read)
    end
  end

end
