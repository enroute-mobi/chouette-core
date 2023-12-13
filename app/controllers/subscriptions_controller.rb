class SubscriptionsController < ApplicationController
  layout "devise"

  before_action :check_feature_is_activated

  def devise_mapping
    Devise.mappings[:user]
  end
  helper_method :devise_mapping

  def resource
    @subscription ||= Subscription.new subscription_params
  end

  def resource_class
    Subscription
  end

  def create
    if resource.save
      sign_in resource.user
      redirect_to "/"
    else
      render "devise/registrations/new"
    end
  end

  def subscription_params
    params.require(:subscription)
      .permit %i(organisation_name user_name email password password_confirmation workbench_invitation_code)
  end

  private
  def check_feature_is_activated
    not_found unless Subscription.enabled?
  end
end
