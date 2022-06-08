class LineProvidersController < ChouetteController
  include ApplicationHelper

  defaults :resource_class => LineProvider

  belongs_to :workbench
  belongs_to :line_referential, singleton: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @line_providers = LineProviderDecorator.decorate(@line_providers, context: {workbench: @workbench})
      }
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: resource.attributes.update(text: resource.name)
      end
      @line_provider = resource.decorate(context: {workbench: @workbench})
      format.html
    end
  end

  protected

  def build_resource
    get_resource_ivar || super.tap do |line_provider|
      line_provider.workbench = @workbench
    end
  end

  def collection
    scope = policy_scope(end_of_association_chain)

    @line_providers ||= begin
      line_providers = scope.order(:name)
      line_providers = line_providers.paginate(:page => params[:page])
      line_providers
    end
  end

  def line_provider_params
    fields = [
      :name,
      :short_name,
      :created_at,
      :updated_at,
      codes_attributes: [:id, :code_space_id, :value, :_destroy]
    ]
    params.require(:line_provider).permit(fields)
  end
end
