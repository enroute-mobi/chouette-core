# frozen_string_literal: true

module Users
  class InvitationsController < Devise::InvitationsController
    include SamlSessionsSupport

    before_action :store_invitation_token_and_sign_in_with_saml, only: %i[edit],
                                                                 if: -> { resource.must_sign_in_with_saml? }

    def new
      not_found
    end

    protected

    def update_resource_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :invitation_token)
    end

    private

    def store_invitation_token_and_sign_in_with_saml
      session["#{resource_name}_invitation_token"] = params['invitation_token']
      sign_in_with_saml
    end
  end
end
