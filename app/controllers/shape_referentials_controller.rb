class ShapeReferentialsController < ChouetteController
  include PolicyChecker
  defaults :resource_class => ShapeReferential

  respond_to :html

  # FIXME required by page_tile helper (?!)

  defaults :singleton => true
  belongs_to :workbench

  def show

    show! do
      @q = @shape_referential.shapes.ransack(params[:q])
      @shapes = ShapeDecorator.decorate(
        shapes_collection,
        context: {
          workbench: workbench
        }
      )
    end
  end

  protected

  alias_method :shape_referential, :resource
  alias_method :workbench, :parent

  def shapes_collection
    @shapes_collection ||= begin
      shapes_scope = shape_referential.shapes
      shapes = shapes_scope.ransack(params[:q]).result
      shapes = shapes.paginate(page: params[:page], per_page: 12)
    end
  end

end
