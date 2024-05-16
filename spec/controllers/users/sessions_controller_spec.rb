# frozen_string_literal: true

RSpec.describe Users::SessionsController, type: :controller do
  # Tests are configured to use CAS and not database authentication, therefore we need to
  # hack warden
  before do
    allow(warden).to receive(:authenticate!).and_wrap_original do |m, *args|
      params = m.receiver.params
      if params[:user] && params[:user][:email] == user.email && params[:user][:password] == 'user_password$42'
        user
      else
        _, opts = m.receiver.send(:_retrieve_scope_and_opts, args)
        throw(:warden, opts)
      end
    end
    allow(User).to receive(:find_for_database_authentication) do |conditions|
      User.find_for_authentication(conditions)
    end
  end
  # and recreate the routes
  # copied from rspec-rails lib/rspec/rails/example/controller_example_group.rb
  before do
    @orig_routes = routes
    resource_path = @controller.controller_path
    resource_module = resource_path.rpartition('/').first.presence
    resource_as = "anonymous_#{resource_path.tr('/', '_')}"
    self.routes = ActionDispatch::Routing::RouteSet.new.tap do |r|
      r.draw do
        resources :sessions, as: resource_as, module: resource_module, path: resource_path, only: %i[create]
      end
    end
  end
  after do
    self.routes = @orig_routes
    @orig_routes = nil
  end

  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  let(:context) do
    Chouette::Factory.create do
      organisation do
        user(password: 'user_password$42', password_confirmation: 'user_password$42')
      end
    end
  end
  let(:organisation) { context.organisation }
  let(:user) { context.user }
  let(:saml_authentication) do
    Authentication::Saml.create!(
      organisation: organisation,
      name: 'SAML',
      subtype: 'google',
      saml_idp_entity_id: 'http://idp.saml.ex/metadata',
      saml_idp_sso_service_url: 'http://idp.saml.ex/sign_in',
      saml_idp_cert: 'some_certificate'
    )
  end
  let(:create_saml_authentication) { false }

  before { saml_authentication if create_saml_authentication }

  subject { response }

  describe '#create' do
    let(:create_params) { {} }

    before { post :create, params: create_params }

    context 'without login nor password' do
      it { is_expected.to render_template(:new) }
    end

    context 'with login only' do
      let(:create_params) { { user: { email: user.email } } }

      it { is_expected.to render_template(:new) }

      context 'with wrong email' do
        let(:create_params) { { user: { email: 'not-an-email' } } }
        it { is_expected.to render_template(:new) }
      end

      context 'with SAML authentication' do
        let(:create_saml_authentication) { true }
        it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }
      end
    end

    context 'with login and password' do
      let(:create_params) { { user: { email: user.email, password: 'user_password$42' } } }

      it { is_expected.to redirect_to('/') }

      it 'signs in user' do
        expect(warden.user).to eq(user)
      end

      context 'when password is empty' do
        let(:create_params) { { user: { email: user.email, password: '' } } }
        it { is_expected.to render_template(:new) }
      end
    end
  end
end
