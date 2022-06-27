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

       @line_providers = collection
      }
    end
  end

  def show
    respond_to do |format|
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
    get_collection_ivar || set_collection_ivar(LineProviderDecorator.decorate(end_of_association_chain.order(:name).paginate(:page => params[:page], per_page: 30),
    context: {
      workbench: @workbench
      })
    )
  end

  def line_provider_params
   params.require(:line_provider).permit(
      :name,
      :short_name,
      :created_at,
      :updated_at,
      codes_attributes: [:id, :code_space_id, :value, :_destroy]
    )
  end
end
