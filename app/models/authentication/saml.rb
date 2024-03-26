# frozen_string_literal: true

module Authentication
  class Saml < Base
    enumerize :subtype, in: %w[google azure]

    validates :saml_idp_entity_id, :saml_idp_sso_service_url, :saml_idp_cert, presence: true

    def self.nullable_attributes
      super + %i[
        saml_idp_slo_service_url
        saml_idp_cert_fingerprint
        saml_idp_cert_fingerprint_algorithm
        saml_email_attribute
      ]
    end

    def devise_saml_settings # rubocop:disable Metrics/MethodLength
      result = {
        idp_sso_service_url: saml_idp_sso_service_url,
        idp_slo_service_url: saml_idp_slo_service_url,
        idp_cert: saml_idp_cert,
        idp_cert_fingerprint: saml_idp_cert_fingerprint,
        idp_cert_fingerprint_algorithm: saml_idp_cert_fingerprint_algorithm,
        authn_context: saml_authn_context
      }

      if subtype_data
        subtype_data::DEVISE_SAML_SETTINGS.each do |k, v|
          result[k] = v if result[k].blank?
        end
      end

      result
    end

    def email_attribute
      result = saml_email_attribute.presence
      result ||= subtype_data::EMAIL_ATTRIBUTE if subtype_data
      result ||= 'email'
      result
    end

    module Subtype
      module Google
        DEVISE_SAML_SETTINGS = {
          name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'
        }.freeze
        EMAIL_ATTRIBUTE = 'primary_email'
      end

      module Azure
        DEVISE_SAML_SETTINGS = {
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
          authn_context: 'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
        }.freeze
        EMAIL_ATTRIBUTE = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'
      end
    end
  end
end
