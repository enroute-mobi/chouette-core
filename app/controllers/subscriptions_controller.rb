# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  layout 'devise'

  before_action :check_feature_is_activated

  def create
    if resource.save
      sign_in resource.user

      if resource.workbench_confirmation
        # TODO: could be shared with WorkbenchConfirmationsController#create
        workbench = resource.workbench_confirmation.workbench
        flash[:notice] =
          t('workbench_confirmations.create.success', workbench: workbench.name, workgroup: workbench.workgroup.name)
        redirect_to workbench_path workbench
      else
        redirect_to '/'
      end
    else
      render 'devise/registrations/new'
    end
  end

  private

  def subscription_params
    params.require(:subscription)
          .permit %i[organisation_name user_name email password password_confirmation workbench_invitation_code]
  end

  def devise_mapping
    Devise.mappings[:user]
  end
  helper_method :devise_mapping

  def subscription
    @subscription ||= Subscription.new subscription_params
  end
  alias resource subscription

  def resource_class
    Subscription
  end

  def check_feature_is_activated
    not_found unless Subscription.enabled?
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
