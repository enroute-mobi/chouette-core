class LineRoutingConstraintZonesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => LineRoutingConstraintZone

  # before_action :decorate_line_routing_constraint_zone, only: %i[show new edit]
  before_action :line_routing_constraint_zone_params, only: [:create, :update]

  belongs_to :workbench
  belongs_to :line_referential, singleton: true

  respond_to :html, :json

  def index
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @line_routing_constraint_zones = LineRoutingConstraintZoneDecorator.decorate(@line_routing_constraint_zones,
        context: { workbench: @workbench })
      }
      format.json
    end
  end

  # def create
  #   create! do |_success, failure|
  #     failure.html do
  #       @macro_list = LineRoutingConstraintZoneDecorator.decorate(@line_routing_constraint_zones, context: { workbench: @workbench })

  #       render 'new'
  #     end
  #   end
  # end

  # def update
  #    update! do |_success, failure|
  #     failure.html do
  #       @macro_list = LineRoutingConstraintZoneDecorator.decorate(@line_routing_constraint_zones, context: { workbench: @workbench })

  #       render 'edit'
  #     end
  #   end
  # end

  # def show
  #   show! do |format|
  #     @line_routing_constraint_zone = @line_routing_constraint_zone.decorate(context: { workbench: @workbench })
  #   end
  # end

  protected

  alias_method :line, :resource
  alias_method :line_referential, :parent

  # def build_resource
  #   get_resource_ivar || super.tap do |line_routing_constraint_zone|
  #     line_routing_constraint_zone.line_provider ||= @workbench.default_line_provider
  #   end
  # end

  def collection
    @line_routing_constraint_zones = parent.line_routing_constraint_zones.paginate(page: params[:page], per_page: 30)
  end

  private

  # def decorate_line_routing_constraint_zone
  #   object = ine_routing_constraint_zone rescue build_resource
  #   @ine_routing_constraint_zone = LineRoutingConstraintZoneDecorator.decorate(
  #     object,
  #     context: {
  #       workbench: line_referential
  #     }
  #   )
  # end

  # def sort_column
  #   params[:sort].presence || 'from_name'
  # end

  # def sort_direction
  #   %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  # end

  # def stop_area_routing_constraint_params
  #   params.require(:stop_area_routing_constraint).permit(:from_id, :to_id, :both_way)
  # end

  def line_routing_constraint_zone_params
    params.require(:line_routing_constraint_zone).permit(
      :name,
      :line_ids,
      :stop_area_ids,
      :created_at,
      :updated_at
    )
  end
end
