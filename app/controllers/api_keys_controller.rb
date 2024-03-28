# frozen_string_literal: true

class ApiKeysController < Chouette::WorkbenchController
  defaults resource_class: ApiKey

  before_action only: :index do
    user_not_authorized unless current_user.has_permission?('api_keys.index')
  end

  def index
    index! do
      @api_keys = ApiKeyDecorator.decorate(
        collection,
        context: { workbench: @workbench }
      )
    end
  end

  def create
    create! do |success, _failure|
      success.html do
        redirect_to workbench_api_keys_path(@workbench)
      end
    end
  end

  def update
    update! do |success, _failure|
      success.html do
        redirect_to workbench_api_keys_path(@workbench)
      end
    end
  end

  private

  def api_key_params
    params.require(:api_key).permit(:name)
  end
end
