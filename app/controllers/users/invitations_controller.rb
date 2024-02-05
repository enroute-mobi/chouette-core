# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  protected

  def invite_params
    params.require(:user).permit(:name, :email, :organisation_id )
  end

  def update_resource_params
     params.require(:user).permit(:name, :email, :password, :password_confirmation, :invitation_token)
  end

  private

  def current_organisation
    current_user.organisation
  end
  helper_method :current_organisation
end
