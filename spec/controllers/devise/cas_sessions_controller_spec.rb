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

  xcontext 'user does not have permission sessions.create' do
    let( :signed_in_user ){ build_stubbed :user }

    it 'cannot login and will be redirected to the login page, with a corresponding message' do
      get :service
      expect(controller).to set_flash[:alert].to(%r{#{I18n.t('devise.sessions.new.unauthorized')}})
      expect(response).to redirect_to "http://cas-portal.example.com/sessions/logout?service=http%3A%2F%2Ftest.host%2Fusers%2Fservice"
    end
  end

  context 'user does have permission sessions.create' do
    let( :signed_in_user ){ build_stubbed :allmighty_user }

    it 'can login and will be redirected to the referentials page' do
      @user.permissions << 'sessions.create'
      get :service
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'cas_service_url' do
    let( :signed_in_user ){ build_stubbed :allmighty_user }
    context 'without custom values' do
      before(:each) do
        allow(Rails.application.config).to receive(:chouette_authentication_settings) { nil }
      end
      it 'should use the request url' do
        expect(controller.send(:cas_service_url)).to eq "http://test.host/users/service"
      end
    end

    context 'with a custom cas_service_url config' do
      before(:each) do
        allow(Rails.application.config).to receive(:chouette_authentication_settings) { { cas_service_url: 'http://foo.com/users/foo' } }
      end
      it 'should use the setup url' do
        expect(controller.send(:cas_service_url)).to eq "http://foo.com/users/foo"
      end
    end
  end
end
