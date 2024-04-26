# frozen_string_literal: true

class RoutingConstraintZonesController < Chouette::ReferentialController
  defaults resource_class: Chouette::RoutingConstraintZone
  respond_to :html, :xml, :json

  # before_action :check_stoppoint_param, only: [:create, :update]

  belongs_to :line, parent_class: Chouette::Line

  def index
    index! do |format|
      format.html do
        @routing_constraint_zones = RoutingConstraintZoneDecorator.decorate(
          @routing_constraint_zones,
          context: {
            workbench: @workbench,
            referential: referential,
            line: parent
          }
        )
      end
      format.json
    end
  end

  def show
    show! do |format|
      @routing_constraint_zone = @routing_constraint_zone.decorate(
        context: {
          workbench: @workbench,
          referential: referential,
          line: parent
        }
      )
    end
  end

  def new
    new! do |format|
      format.html
      format.js {
        # Get selected route in the form view
        @route = @line.routes.find params[:route_id] if params[:route_id]
        # Get the routing_constraint_zone, the main use is when validation failed
        routing_constraint_zone = @line.routing_constraint_zones.new(JSON(params[:routing_constraint_zone_json])) if params[:routing_constraint_zone_json]
        @routing_constraint_zone = routing_constraint_zone || build_resource
      }
    end
  end

  protected

  alias_method :routing_constraint_zone, :resource
  alias_method :line, :parent
  alias parent_for_parent_policy referential

  def collection
    @q = line.routing_constraint_zones.ransack(params[:q])

    @routing_constraint_zones ||= begin
      routing_constraint_zones = sort_collection
      routing_constraint_zones = routing_constraint_zones.paginate(
        page: params[:page],
        per_page: 10
      )
    end
  end

  def build_resource
    super.tap do |rcz|
      if params[:opposite_zone_id]
        opposite_zone = @line.routing_constraint_zones.find(params[:opposite_zone_id])
        rcz.route = opposite_zone.route.opposite_route
        rcz.name = Chouette::RoutingConstraintZone.tmf('opposite_zone_name', name: opposite_zone.name)
        rcz.stop_points = []
        opposite_zone.stop_points.light.each do |stop_point|
          rcz.stop_points << rcz.route.stop_points.light.find{|sp| stop_point.stop_area_id == sp.stop_area_id }
        end
      end
    end
  end

  private
  def sort_column
    (
      Chouette::RoutingConstraintZone.column_names +
      [
        'stop_points_count',
        'route'
      ]
    ).include?(params[:sort]) ? params[:sort] : 'name'
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def sort_collection
    sort_by = sort_column

    if sort_by == 'stop_points_count'
      @q.result.order_by_stop_points_count(sort_direction)
    elsif sort_by == 'route'
      @q.result.order_by_route_name(sort_direction)
    else
      @q.result.order(sort_column + ' ' + sort_direction)
    end
  end

  def routing_constraint_zone_params
    params.require(:routing_constraint_zone).permit(
      :name,
      { stop_point_ids: [] },
      :line_id,
      :route_id,
      :objectid,
      :object_version,
    )
  end

  def check_stoppoint_param
    spArr = []
    if params.require(:routing_constraint_zone)[:stop_point_ids] and params.require(:routing_constraint_zone)[:stop_point_ids].length >= 2
      params.require(:routing_constraint_zone)[:stop_point_ids].each do |k,v|
        spArr << v
      end
      params.require(:routing_constraint_zone)[:stop_point_ids] = spArr
    else
      Rails.logger.error("Error: An ITL must have at least two stop points")
    end
  end
end
