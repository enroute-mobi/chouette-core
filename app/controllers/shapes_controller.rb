class ShapesController < ChouetteController
  # FIXME required by page_tile helper (?!)
  defaults :resource_class => Shape

  belongs_to :workbench
  belongs_to :shape_referential, singleton: true

  respond_to :html
  respond_to :kml, :only => [:index, :show]

  protected

  alias_method :shape_referential, :parent

  def collection
    @shapes ||= begin
      scope = shape_referential.shapes
      shapes = scope.ransack(params[:q]).result
      shapes = shapes.paginate(page: params[:page], per_page: 12)
    end
  end

  private

  def resource
    super.decorate(context: { workbench: @workbench })
  end

  def shape_params
    params.require(:shape).permit(:name)
  end

end
