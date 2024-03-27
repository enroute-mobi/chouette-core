# frozen_string_literal: true

module SamlSessionsSupport
  extend ActiveSupport::Concern

  include DeviseSamlAuthenticatable::SamlConfig

  private

  def sign_in_with_saml
    idp_entity_id = resource.organisation.authentication.saml_idp_entity_id

    # copied from Devise::SamlSessionsController#new (this code has to be updated every time the gem is updated)
    auth_request = OneLogin::RubySaml::Authrequest.new
    # auth_params = { RelayState: relay_state } if relay_state # commented out since Devise.saml_relay_state is nil
    action = auth_request.create(saml_config(idp_entity_id, request), {})
    session[:saml_transaction_id] = auth_request.request_id if auth_request.respond_to?(:request_id)
    redirect_to action, allow_other_host: true
  end
end
