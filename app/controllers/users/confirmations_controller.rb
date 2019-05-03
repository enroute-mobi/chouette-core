class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_after_action :set_creator_metadata

  def create
    if !params[:confirmation_token]
      flash[:warning] = t('notice.devise.confirmation.missing_token')
      redirect_to new_confirmation_path(:user)
    elsif User.find_by_email(params[:email])&.confirmed?
      flash[:success] = t('notice.devise.confirmation.already_confirmed')
      redirect_to rooth_path
    else
      super
    end
  end
end