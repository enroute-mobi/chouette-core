# frozen_string_literal: true

class UsersController < Chouette::ResourceController
  include PolicyChecker

  before_action :authorize_resource, except: [:create, :index, :new, :new_invitation, :invite]
  before_action :authorize_resource_class, only: [:create, :index, :new, :new_invitation, :invite]

  defaults :resource_class => User

  def invite
    already_existing, user = User.invite(user_params.to_h.update(organisation: current_organisation, from_user: current_user).symbolize_keys)
    if already_existing
      @error = true
      @existing_user = user
      @user = User.new user_params
      render "new_invitation"
    else
      flash[:notice] = I18n.t('users.new_invitation.success')
      redirect_to [:organisation, user]
    end
  end

  def update
    update! do
      organisation_user_path(@user)
    end
  end

  def destroy
    destroy! do |success, failure|
      success.html { redirect_to organisation_path }
    end
  end

  def block
    resource.lock_access!
    redirect_back fallback_location: root_path
  end

  def unblock
    resource.unlock_access!
    redirect_back fallback_location: root_path
  end

  def reinvite
    resource.invite_from_user! current_user
    flash[:notice] = t('users.actions.reinvite_flash')
    redirect_back fallback_location: root_path
  end

  def reset_password
    resource.send_reset_password_instructions
    flash[:notice] = t('users.actions.reset_password_flash')
    redirect_back fallback_location: root_path
  end

  private
  def user_params
    keys = %i[name profile]
    keys << :email unless params[:action] == 'update'
    params.require(:user).permit(*keys)
  end

  def resource
    @user = super.decorate
  end
end
