# frozen_string_literal: true

RSpec.describe Authentication::Saml, type: :model do
  it { is_expected.to enumerize(:subtype).in(%w[google azure]) }
  it { is_expected.to validate_presence_of(:saml_idp_entity_id) }
  it { is_expected.to validate_presence_of(:saml_idp_sso_service_url) }
  it { is_expected.to validate_presence_of(:saml_idp_cert) }

  describe '.nullable_attributes' do
    subject { described_class.nullable_attributes }
    it do
      is_expected.to match_array(
        %i[
          subtype
          saml_idp_slo_service_url
          saml_idp_cert_fingerprint
          saml_idp_cert_fingerprint_algorithm
          saml_email_attribute
        ]
      )
    end
  end

  describe '#sign_in_url' do
    subject { saml_authentication.sign_in_url(helper) }

    let(:organisation) { Chouette::Factory.create { organisation }.organisation }
    let(:saml_authentication) { Authentication::Saml.new(organisation: organisation) }
    let(:helper) do
      h = double
      expect(h).to(
        receive(:organisation_code_new_saml_user_session_url).with(organisation.code)
                                                             .and_return('http://test.ex/users/saml/sign_in/code')
      )
      h
    end

    it { is_expected.to eq('http://test.ex/users/saml/sign_in/code') }
  end

  describe '#devise_saml_settings' do
    subject { saml_authentication.devise_saml_settings }

    let(:subtype) { nil }
    let(:saml_idp_sso_service_url) { 'http://idp.saml.ex/sign_in' }
    let(:saml_idp_slo_service_url) { 'http://idp.saml.ex/sign_out' }
    let(:saml_idp_cert) { 'some_certificate' }
    let(:saml_idp_cert_fingerprint) { 'AA::BB::CC' }
    let(:saml_idp_cert_fingerprint_algorithm) { 'http://www.w3.org/2000/09/xmldsig#sha256' }
    let(:saml_authn_context) { nil }
    let(:saml_authentication) do
      Authentication::Saml.new(
        subtype: subtype,
        saml_idp_sso_service_url: saml_idp_sso_service_url,
        saml_idp_slo_service_url: saml_idp_slo_service_url,
        saml_idp_cert: saml_idp_cert,
        saml_idp_cert_fingerprint: saml_idp_cert_fingerprint,
        saml_idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
        saml_authn_context: saml_authn_context
      )
    end

    context 'without subtype' do
      it do
        is_expected.to eq(
          {
            idp_sso_service_url: saml_idp_sso_service_url,
            idp_slo_service_url: saml_idp_slo_service_url,
            idp_cert: saml_idp_cert,
            idp_cert_fingerprint: saml_idp_cert_fingerprint,
            idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
            authn_context: nil
          }
        )
      end
    end

    context 'with google subtype' do
      let(:subtype) { 'google' }

      it do
        is_expected.to eq(
          {
            name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
            idp_sso_service_url: saml_idp_sso_service_url,
            idp_slo_service_url: saml_idp_slo_service_url,
            idp_cert: saml_idp_cert,
            idp_cert_fingerprint: saml_idp_cert_fingerprint,
            idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
            authn_context: nil
          }
        )
      end
    end

    context 'with azure subtype' do
      let(:subtype) { 'azure' }

      it do
        is_expected.to eq(
          {
            name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
            idp_sso_service_url: saml_idp_sso_service_url,
            idp_slo_service_url: saml_idp_slo_service_url,
            idp_cert: saml_idp_cert,
            idp_cert_fingerprint: saml_idp_cert_fingerprint,
            idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
            authn_context: 'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
          }
        )
      end

      context 'when saml_authn_context is filled' do
        let(:saml_authn_context) { 'urn:oasis:names:tc:SAML:2.0:classes:Kerberos' }

        it do
          is_expected.to eq(
            {
              name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
              idp_sso_service_url: saml_idp_sso_service_url,
              idp_slo_service_url: saml_idp_slo_service_url,
              idp_cert: saml_idp_cert,
              idp_cert_fingerprint: saml_idp_cert_fingerprint,
              idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
              authn_context: 'urn:oasis:names:tc:SAML:2.0:classes:Kerberos'
            }
          )
        end
      end

      context 'when saml_email_attribute is blank' do
        let(:saml_authn_context) { '' }

        it do
          is_expected.to eq(
            {
              name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
              idp_sso_service_url: saml_idp_sso_service_url,
              idp_slo_service_url: saml_idp_slo_service_url,
              idp_cert: saml_idp_cert,
              idp_cert_fingerprint: saml_idp_cert_fingerprint,
              idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
              authn_context: 'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
            }
          )
        end
      end
    end
  end

  describe '#email_attribute' do
    subject { saml_authentication.email_attribute }

    let(:subtype) { nil }
    let(:saml_email_attribute) { nil }
    let(:saml_authentication) do
      Authentication::Saml.new(
        subtype: subtype,
        saml_email_attribute: saml_email_attribute
      )
    end

    context 'without subtype' do
      it { is_expected.to eq('email') }
    end

    context 'with google' do
      let(:subtype) { 'google' }

      it { is_expected.to eq('primary_email') }

      context 'when saml_email_attribute is filled' do
        let(:saml_email_attribute) { 'some_other_email' }
        it { is_expected.to eq('some_other_email') }
      end

      context 'when saml_email_attribute is blank' do
        let(:saml_email_attribute) { '' }
        it { is_expected.to eq('primary_email') }
      end
    end

    context 'with azure' do
      let(:subtype) { 'azure' }

      it { is_expected.to eq('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress') }
    end
  end
end
