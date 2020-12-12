  class StopAreaProvidersController < ChouetteController
  include ApplicationHelper

  defaults :resource_class => StopAreaProvider
  belongs_to :workbench
  belongs_to :stop_area_referential, singleton: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_area_providers = StopAreaProviderDecorator.decorate(@stop_area_providers, context: {referential: parent})
      }
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: resource.attributes.update(text: resource.name)
      end
      @stop_area_provider = resource.decorate(context: {referential: parent})
      format.html
    end
  end

  def autocomplete
    scope = policy_scope(parent.stop_area_providers)
    args  = [].tap{|arg| 2.times{arg << "%#{params[:q]}%"}}
    @stop_area_providers = scope.where("unaccent(name) ILIKE unaccent(?) OR objectid ILIKE ?", *args).limit(50)
    @stop_area_providers
  end

  def collection
    scope = policy_scope(parent.stop_area_providers)

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
