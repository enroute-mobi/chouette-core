RSpec.describe Devise::CasSessionsController, type: :controller do

  before do
    @user = signed_in_user
    allow_any_instance_of(Warden::Proxy).to receive(:authenticate).and_return @user
    allow_any_instance_of(Warden::Proxy).to receive(:authenticate!).and_return @user
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end


  context 'login is correctly redirected' do
    let( :signed_in_user ){ build_stubbed :user }
    it 'to #service' do
      get :new
      expect( response ).to be_redirect
      expect( response.redirect_url ).to eq("http://cas-portal.example.com/sessions/login?service=http%3A%2F%2Ftest.host%2Fusers%2Fservice")
    end
  end

  context 'user does not have permission sessions.create' do
    let( :signed_in_user ){ build_stubbed :user }

    it 'cannot login and will be redirected to the login page, with a corresponding message' do
      get :service
      expect(controller).to set_flash[:alert].to(%r{Vous ne pouvez pas vous connecter car vous n'avez pas les permissions})
      expect(response).to redirect_to "http://cas-portal.example.com/sessions/logout?service=http%3A%2F%2Ftest.host%2Fusers%2Fservice"
    end
  end

  context 'user does have permission sessions.create' do
    let( :signed_in_user ){ build_stubbed :allmighty_user }

    it 'can login and will be redirected to the referentials page' do
      @user.permissions << 'sessions.create'
      get :service
      expect(response).to redirect_to(authenticated_root_path)
    end
  end
end
