# frozen_string_literal: true

class ShapesController < Chouette::TopologicReferentialController
  # FIXME required by page_tile helper (?!)
  defaults :resource_class => Shape

  respond_to :html
  respond_to :json, only: %i[index]
  respond_to :geojson, only: %i[index show]

  def index
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search(Search::Shape.attributes_from_params(params))
    end

    index! do |format|
      format.geojson do
        @shapes = @shapes.includes(:waypoints)
        render 'shapes/index'
      end

      format.html {
        @shapes = ShapeDecorator.decorate(
          @shapes.includes(shape_provider: :workbench),
          context: {
            workbench: workbench
          }
        )
      }
    end
  end

  def show
    show! do |format|
      format.geojson { render 'shapes/show' }
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::Shape)
  end

  protected

  def scope
    parent.shapes
  end

  def search
    @search ||= ::Search::Shape.from_params(params, workbench: workbench)
  end

  def collection
    @shapes ||= search.search(scope) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  private

  def resource
    super.decorate(context: { workbench: workbench })
  end

  def shape_params
    @shape_params ||= params.require(:shape).permit(
      :name,
      :shape_provider_id,
      codes_attributes: %i[id code_space_id value _destroy]
    )
  end
end
