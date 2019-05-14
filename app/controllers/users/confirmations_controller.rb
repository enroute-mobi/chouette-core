class Users::ConfirmationsController < Devise::ConfirmationsController
  skip_after_action :set_creator_metadata

  def show
    if !params[:confirmation_token]
      flash[:warning] = t('notice.devise.confirmation.missing_token')
      redirect_to root_path
    elsif User.find_by_confirmation_token(params[:confirmation_token])&.confirmed?
      flash[:success] = t('notice.devise.confirmation.already_confirmed')
      redirect_to root_path
    else
      super
    end
  end
end
