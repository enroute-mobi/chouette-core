# frozen_string_literal: true

RSpec.describe Users::SamlSessionsController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  let(:context) do
    Chouette::Factory.create do
      organisation(:organisation)
    end
  end
  let(:organisation) { context.organisation(:organisation) }
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

  subject { response }

  describe '#new' do
    let(:param_organisation_code) { saml_authentication.organisation.code }
    let(:params) do
      params = {}
      params[:organisation_code] = param_organisation_code if param_organisation_code
      params
    end

    before do
      get :new, params: params
    rescue OneLogin::RubySaml::SettingError => e
      @exception = e
    end

    it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }

    context 'without organisation_code' do
      let(:param_organisation_code) { nil }

      it 'fails' do
        expect(@exception).not_to be_nil
      end
    end

    context 'when organisation_code is a non-existing organisation' do
      let(:param_organisation_code) { 'i-do-not-exist' }

      it 'fails' do
        expect(@exception).not_to be_nil
      end
    end

    context 'when organisation has no SAML authentication' do
      let(:param_organisation_code) { organisation.code }

      it 'fails' do
        expect(@exception).not_to be_nil
      end
    end
  end

  describe '#create' do
    let(:user_email) { 'email@test.ex' }
    let(:context) do
      Chouette::Factory.create do
        organisation(:organisation) do
          user(:user, email: 'email@test.ex')
        end
      end
    end
    let(:user) { context.user(:user) }

    let(:saml_response_issuer) { saml_authentication.saml_idp_entity_id }
    let(:saml_response_attributes) { { 'primary_email' => [user_email.dup] } }

    before do
      dbl_saml_response = double(
        :saml_response,
        issuers: [saml_response_issuer],
        is_valid?: true,
        attributes: OneLogin::RubySaml::Attributes.new(saml_response_attributes),
        sessionindex: '_16f570fbc0315007a0355dfea6b3c46c'
      )
      allow(OneLogin::RubySaml::Response).to receive(:new).and_return(dbl_saml_response)

      begin
        post :create, params: { SAMLResponse: 'whatever' }
      rescue OneLogin::RubySaml::SettingError => e
        @exception = e
      end
    end

    it { is_expected.to redirect_to('/') }

    it 'signs in user' do
      expect(warden.user).to eq(user)
    end

    context 'when issuer is a non-existing authentication' do
      let(:saml_response_issuer) { 'http://i-do-not.exist/saml/metadata' }

      it 'fails' do
        expect(@exception).not_to be_nil
      end
    end

    context 'when email is not found among attributes' do
      let(:saml_response_attributes) { { 'email' => user_email } }
      it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }
    end

    context 'when no user exist with this email' do
      let(:saml_response_attributes) { { 'primary_email' => 'does-not-exist@test.ex' } }
      it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }
    end

    context 'when user belongs to another organisation' do
      let(:context) do
        Chouette::Factory.create do
          organisation(:organisation)
          organisation do
            user(:user, email: 'email@test.ex')
          end
        end
      end
      # NOTE: it is the gem behavior but this will unfortunately lead to infinite loops
      it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }
    end
  end

  describe '#metadata' do
    let(:param_organisation_code) { saml_authentication.organisation.code }
    let(:params) do
      params = {}
      params[:organisation_code] = param_organisation_code if param_organisation_code
      params
    end

    before do
      get :metadata, params: params
      @xml = Nokogiri::XML(response.body)
    end

    it 'renders metadata' do
      expect(@xml.at('//md:EntityDescriptor')['entityID']).to(
        eq("http://test.host/users/saml/metadata/#{organisation.code}")
      )
      expect(@xml.at('//md:NameIDFormat').text).to eq('urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress')
      acs = @xml.at('//md:AssertionConsumerService')
      expect(acs['Location']).to eq('http://test.host/users/saml/auth')
      expect(acs['Binding']).to eq('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST')
    end

    context 'without organisation_code' do
      let(:param_organisation_code) { nil }

      it 'render empty metadata' do
        expect(@xml.at('//md:EntityDescriptor')['entityID']).to be_nil
      end
    end

    context 'when organisation_code is a non-existing organisation' do
      let(:param_organisation_code) { 'i-do-not-exist' }

      it 'render empty metadata' do
        expect(@xml.at('//md:EntityDescriptor')['entityID']).to be_nil
      end
    end

    context 'when organisation has no SAML authentication' do
      let(:param_organisation_code) { organisation.code }

      it 'render empty metadata' do
        expect(@xml.at('//md:EntityDescriptor')['entityID']).to be_nil
      end
    end
  end
end
