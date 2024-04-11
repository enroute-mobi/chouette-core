# frozen_string_literal: true

module Users
  class SamlSessionsController < Devise::SamlSessionsController
    before_action :put_organisation_idp_entity_id_in_params_from_organisation_code, only: %i[metadata]

    private

    def put_organisation_idp_entity_id_in_params_from_organisation_code
      params[:idp_entity_id] = get_idp_entity_id(params)
    end
  end
end
