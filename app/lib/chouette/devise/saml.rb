# frozen_string_literal: true

module Chouette
  module Devise
    module Saml
      def self.find_authentication_by_idp_entity_id(idp_entity_id)
        ::Authentication::Saml.find_by(saml_idp_entity_id: idp_entity_id)
      end

      def self.settings(idp_entity_id, request) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        authentication = find_authentication_by_idp_entity_id(idp_entity_id)
        return {} unless authentication

        url_options = { protocol: request.protocol, host: request.host, port: request.port }

        authentication.devise_saml_settings.merge(
          {
            assertion_consumer_service_url: Rails.application.routes.url_helpers.saml_user_session_url(url_options),
            assertion_consumer_service_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
            sp_entity_id: Rails.application.routes.url_helpers.organisation_code_metadata_user_session_url(
              url_options.merge(organisation_code: authentication.organisation.code)
            )
          }
        )
      end

      def self.entity_id(params)
        old_entity_id = DeviseSamlAuthenticatable::DefaultIdpEntityIdReader.entity_id(params)
        return old_entity_id if old_entity_id

        # this method is called in many different contexts, it is therefore preferable to limit its perimeter
        if params[:controller] == 'users/saml_sessions' && %w[new metadata].include?(params[:action]) \
            && params[:organisation_code].present?
          Organisation
            .where(code: params[:organisation_code])
            .joins(:authentication)
            .pluck('authentications.saml_idp_entity_id')
            .first
        end
      end

      class AttributeMapResolver < DeviseSamlAuthenticatable::DefaultAttributeMapResolver
        def attribute_map
          idp_entity_id = saml_response.issuers.first
          authentication = ::Chouette::Devise::Saml.find_authentication_by_idp_entity_id(idp_entity_id)
          return {} unless authentication

          { authentication.email_attribute => 'email' }
        end
      end
    end
  end
end
