# frozen_string_literal: true

class ShapesController < Chouette::TopologicReferentialController
  include PolicyChecker
  # FIXME required by page_tile helper (?!)
  defaults :resource_class => Shape

  belongs_to :workbench
  belongs_to :shape_referential, singleton: true

  respond_to :html
  respond_to :json, only: %i[index]
  respond_to :geojson, only: %i[index show]

  def index
    index! do |format|
      format.geojson { render 'shapes/index.geo' }

      format.html {
        @shapes = ShapeDecorator.decorate(
          @shapes,
          context: {
            workbench: @workbench
          }
        )
      }
    end
  end

  def show
    show! do |format|
      format.geojson { render 'shapes/show.geo' }
    end
  end

  protected

  alias_method :shape_referential, :parent

  def collection
    @q = shape_referential.shapes.ransack(params[:q])
    @shapes ||= @q.result.paginate(page: params[:page], per_page: 12)
  end

  private

  def resource
    super.decorate(context: { workbench: @workbench })
  end

  def shape_params
    params.require(:shape).permit(:name)
  end

end
