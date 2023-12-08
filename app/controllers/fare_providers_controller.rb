# frozen_string_literal: true

class FareProvidersController < Chouette::FareReferentialController
  include ApplicationHelper
  include PolicyChecker

  defaults resource_class: Fare::Provider

  belongs_to :workbench

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        @fare_providers = Fare::ProviderDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  protected

  alias fare_provider resource
  alias workbench parent

  def resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench }))
  end

  def build_resource
    get_resource_ivar || set_resource_ivar(super.decorate(context: { workbench: workbench }))
  end

  def fare_provider_params
    fields = [
      :name,
      :short_name,
      codes_attributes: %i[id code_space_id value _destroy]
    ]
    params.require(:fare_provider).permit(fields)
  end
end
