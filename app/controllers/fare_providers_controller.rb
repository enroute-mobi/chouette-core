class FareProvidersController < ChouetteController
  include ApplicationHelper

  defaults :resource_class => Fare::Provider

  belongs_to :workbench

  respond_to :html, :json

  def index
    index! do |format|
      format.html do
        @fare_providers = FareProviderDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  protected

  def build_resource
    get_resource_ivar || super.tap do |fare_provider|
      fare_provider.workbench = @workbench
    end
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
