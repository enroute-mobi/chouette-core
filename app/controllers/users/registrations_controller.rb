class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name,
      :password,
      :password_confirmation,
      :current_password,
      :user_locale,
      :time_zone])
  end

  def update_resource(resource, params)
    if params[:password].present?
      resource.update_with_password(params)
    else
      params.delete :password
      params.delete :password_confirmation
      params.delete :current_password
      resource.update(params)
    end
  end

  private

end
