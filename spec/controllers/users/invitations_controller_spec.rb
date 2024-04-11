# frozen_string_literal: true

RSpec.describe Users::InvitationsController, type: :controller do
  before do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  let(:context) do
    Chouette::Factory.create do
      organisation do
        user
      end
    end
  end
  let(:organisation) { context.organisation }
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
  let(:from_user) { context.user }

  let(:create_saml_authentication) { false }

  let(:user) do
    User.invite(
      email: 'invited@test.ex',
      name: 'invited',
      profile: 'visitor',
      organisation: organisation,
      from_user: from_user
    )[1]
  end
  let(:invitation_token) { user.instance_variable_get(:@raw_invitation_token) }

  before { saml_authentication if create_saml_authentication }

  subject { response }

  describe '#edit' do
    before { get :edit, params: { invitation_token: invitation_token } }

    it { is_expected.to render_template(:edit) }

    context 'with SAML authentication' do
      let(:create_saml_authentication) { true }

      it { is_expected.to redirect_to(/\A#{saml_authentication.saml_idp_sso_service_url}\?SAMLRequest=/) }

      it 'stores invitation token in session' do
        session_invitation_token = session['user_invitation_token']
        expect(session_invitation_token).to be_present
        expect(session_invitation_token).to eq(invitation_token)
      end
    end
  end
end
