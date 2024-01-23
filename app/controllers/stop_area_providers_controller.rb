# frozen_string_literal: true

class StopAreaProvidersController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  defaults :resource_class => StopAreaProvider

  respond_to :html, :json

  def index # rubocop:disable Metrics/MethodLength
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_area_providers = StopAreaProviderDecorator.decorate(
          @stop_area_providers,
          context: {
            workbench: workbench
          }
        )
      }
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: resource.attributes.update(text: resource.name)
      end
      @stop_area_provider = resource.decorate(context: { workbench: workbench })
      format.html
    end
  end

  protected

  def build_resource
    get_resource_ivar || super.tap do |stop_area_provider|
      stop_area_provider.workbench = workbench
    end
  end

  def collection
    scope = policy_scope(end_of_association_chain)

    @stop_area_providers ||= begin
      stop_area_providers = scope.order(:name)
      stop_area_providers = stop_area_providers.paginate(:page => params[:page])
      stop_area_providers
    end
  end

  def stop_area_provider_params
    fields = [
      :name,
      {stop_area_ids: []}
    ]
    params.require(:stop_area_provider).permit(fields)
  end
end
