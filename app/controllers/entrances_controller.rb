class EntrancesController < ChouetteController
  include ApplicationHelper
  # include ReferentialSupport
  include PolicyChecker

  defaults :resource_class => Entrance

  before_action :entrance_params, only: [:create, :update]

  belongs_to :workbench
  belongs_to :stop_area_referential, singleton: true

  respond_to :html, :xml, :json

  def index
    # index! do
    #   @entrances = EntranceDecorator.decorate(@entrances, context: { workbench: @workbench })
    # end

    respond_to do |format|
      format.html do
        index! do
          @entrances = EntranceDecorator.decorate(
            @entrances,
            context: {
              workbench: @workbench
            }
          )

          if collection.out_of_bounds?
            redirect_to params.merge(:page => 1)
          end
        end
      end
    end
  end

  def show
    show! do |format|
      @entrance = @entrance.decorate context: { workbench: @workbench }
    end
  end

  def update
    update! do
      if entrance_params[:entrance_ids]
        workbench_stop_area_referential_entrances_path @workbench, @entrance
      else
        workbench_stop_area_referential_entrance_path @workbench, @entrance
      end
    end
  end

  protected

  alias_method :entrance, :resource
  alias_method :stop_area_referential, :parent

  def collection
    @entrances = parent.entrances.paginate(page: params[:page], per_page: 30)
  end

  # def build_resource
  #   super.tap do |rcz|
  #     if params[:opposite_zone_id]
  #       opposite_zone = @line.routing_constraint_zones.find(params[:opposite_zone_id])
  #       rcz.route = opposite_zone.route.opposite_route
  #       rcz.name = Chouette::RoutingConstraintZone.tmf('opposite_zone_name', name: opposite_zone.name)
  #       rcz.stop_points = []
  #       opposite_zone.stop_points.light.each do |stop_point|
  #         rcz.stop_points << rcz.route.stop_points.light.find{|sp| stop_point.stop_area_id == sp.stop_area_id }
  #       end
  #     end
  #   end
  # end

  private

  def sort_column
    params[:sort].presence || 'departure'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def entrance_params
    params.require(:entrance).permit(
      :objectid,
      :stop_area_id,
      :stop_area_provider_id,
      :name,
      :short_name,
      :entry_flag,
      :exit_flag,
      :entrance_type,
      :description,
      :position_input,
      :address,
      :zip_code,
      :city_name,
      :country,
      :created_at,
      :updated_at,
    )
  end

  # def check_stoppoint_param
  #   spArr = []
  #   if params.require(:routing_constraint_zone)[:stop_point_ids] and params.require(:routing_constraint_zone)[:stop_point_ids].length >= 2
  #     params.require(:routing_constraint_zone)[:stop_point_ids].each do |k,v|
  #       spArr << v
  #     end
  #     params.require(:routing_constraint_zone)[:stop_point_ids] = spArr
  #   else
  #     Rails.logger.error("Error: An ITL must have at least two stop points")
  #   end
  # end

end
