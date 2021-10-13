class RoutesController < ChouetteController
  include ReferentialSupport
  include PolicyChecker
  defaults :resource_class => Chouette::Route

  respond_to :html, :xml, :json, :geojson
  respond_to :kml, :only => :show
  respond_to :js, :only => :show
  respond_to :geojson, :only => :show

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line, :optional => true, :polymorphic => true
  end
  before_action :define_candidate_opposite_routes, only: [:new, :edit, :fetch_opposite_routes]

  def index
    index! do |format|
      format.html { redirect_to referential_line_path(@referential, @line) }
    end
  end

  def edit_boarding_alighting
    @route = route
  end

  def save_boarding_alighting
    @route = route
    if @route.update_attributes!(route_params)
      redirect_to referential_line_route_path(@referential, @line, @route)
    else
      render "edit_boarding_alighting"
    end
  end

  def show
    @route_sp = route.stop_points
    if sort_sp_column && sort_sp_direction
      @route_sp = @route_sp.order(sort_sp_column + ' ' + sort_sp_direction)
    else
      @route_sp = @route_sp.order(:position)
    end

    show! do |format|
      @route = @route.decorate(context: {
        referential: @referential,
        line: @line
      })

      @route_sp = StopPointDecorator.decorate(@route_sp)

      format.geojson { render 'routes/show.geo' }
    end
  end

  def destroy
    destroy! do |success, failure|
      success.html { redirect_to referential_line_path(@referential,@line) }
    end
  end

  def create
    create! do |success, failure|
      failure.json { render json: { message: t('flash.actions.create.error', resource_name: t('activerecord.models.route.one')), status: 422 } }
      success.json { render json: { message: t('flash.actions.create.notice', resource_name: t('activerecord.models.route.one')), status: 200 } }
    end
  end

  def update
    update! do |success, failure|
      failure.json { render json: { message: t('flash.actions.update.error', resource_name: t('activerecord.models.route.one')), status: 422 } }
      success.json { render json: { message: t('flash.actions.update.notice', resource_name: t('activerecord.models.route.one')) }, status: 200 }
    end
  end

  def duplicate
    source = Chouette::Route.find(params[:id])
    route = source.duplicate params[:opposite]
    flash[:notice] = t('routes.duplicate.success')
    redirect_to referential_line_path(@referential, route.line)
  end

  def costs
    @route = resource
  end

  # React endpoints

  def fetch_user_permissions
    perms =
    %w{create destroy update}.inject({}) do | permissions, action |
        permissions.merge({"routes.#{action}": policy(Chouette::Route).authorizes_action?(action)})
      end.to_json

      render json: perms
  end

  def fetch_opposite_routes
    render json: { outbound: @backward, inbound: @forward }
  end


  protected

  alias_method :route, :resource

  def collection
    @q = parent.routes.ransack(params[:q])
    @routes ||=
      begin
        routes = @q.result(:distinct => true).order(:name)
        routes = routes.paginate(:page => params[:page]) if @per_page.present?
        routes
      end
  end

  def define_candidate_opposite_routes
    scope = if params[:route_id].present?
      route = parent.routes.find(params[:route_id])
      parent.routes.where(opposite_route: [nil, route])
    else
      parent = @referential.lines.find(params[:line_id])
      parent.routes.where(opposite_route: nil)
    end
    @forward  = scope.where(wayback: :outbound)
    @backward = scope.where(wayback: :inbound)
  end

  private

  def sort_sp_column
    route.stop_points.column_names.include?(params[:sort]) ? params[:sort] : 'position'
  end
  def sort_sp_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def route_params
    params.require(:route).permit(
      :line_id,
      :objectid,
      :object_version,
      :name,
      :comment,
      :opposite_route_id,
      :published_name,
      :number,
      :direction,
      :wayback,
      stop_points_attributes: [:id, :_destroy, :position, :stop_area_id, :for_boarding, :for_alighting]
    )
  end

end
