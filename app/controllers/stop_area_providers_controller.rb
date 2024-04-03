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
    get_resource_ivar || set_resource_ivar(
      end_of_association_chain.send(method_for_build, *resource_params)
    ).tap do |stop_area_provider|
      stop_area_provider.workbench = workbench
    end
  end

  def update_resource(object, attributes)
    object.update(*attributes)
  end

  def collection
    @stop_area_providers ||= begin
      stop_area_providers = end_of_association_chain.order(:name)
      stop_area_providers = stop_area_providers.paginate(:page => params[:page])
      stop_area_providers
    end
  end

  def stop_area_provider_params
    return @stop_area_provider_params if @stop_area_provider_params

    fields = [
      :name,
      {stop_area_ids: []}
    ]
    @stop_area_provider_params = params.require(:stop_area_provider).permit(fields)
  end

  alias parent_for_parent_policy parent
end
