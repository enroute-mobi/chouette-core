# frozen_string_literal: true

class RoutesController < Chouette::ReferentialController
  defaults resource_class: Chouette::Route

  respond_to :html, :xml, :json, :geojson
  respond_to :js, :only => :show
  respond_to :geojson, only: %i[show index]
  respond_to :json, only: %i[retrieve_nearby_stop_areas autocomplete_stop_areas]

  belongs_to :line, parent_class: Chouette::Line, optional: true, polymorphic: true

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[
    new create index show
    costs
    retrieve_nearby_stop_areas
    autocomplete_stop_areas
    fetch_opposite_routes
    fetch_user_permissions
  ]
  before_action :define_candidate_opposite_routes, only: %i[new edit fetch_opposite_routes]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  def index
    @routes = collection
    index! do |format|
      format.html { redirect_to workbench_referential_line_path(current_workbench, @referential, @line) }
      format.geojson { render 'routes/index.geo' }
    end
  end

  def edit_boarding_alighting
    @route = route
  end

  def save_boarding_alighting
    @route = route
    if @route.update!(route_params)
      redirect_to workbench_referential_line_route_path(current_workbench, @referential, @line, @route)
    else
      render 'edit_boarding_alighting'
    end
  end

  # Retrieve nearby stop areas for one stop area in route editor
  def retrieve_nearby_stop_areas
    stop_area_id = params[:stop_area_id]
    area_type = params[:target_type]
    workbench = route.referential.workbench

    unless (stop_area = workbench.stop_areas.where(deleted_at: nil).find(stop_area_id))
      raise ActiveRecord::RecordNotFound
    end

    @stop_areas = stop_area.around(referential.stop_areas.where(area_type: area_type), 300)
  end

  # Retrieve stop areas for autocomplete in route editor
  def autocomplete_stop_areas
    scope = referential.workbench.stop_areas.where(deleted_at: nil)
    unless current_user.organisation.has_feature?('route_stop_areas_all_types')
      scope = scope.where(kind: :non_commercial).or(scope.where(area_type: referential.stop_area_referential.available_stops))
    end

    @stop_areas = text.present? ? scope.by(text).limit(50) : Chouette::StopArea.none
  end

  def show
    @route_sp = route.stop_points
    @route_sp = if sort_sp_column && sort_sp_direction
                  @route_sp.order("#{sort_sp_column} #{sort_sp_direction}")
                else
                  @route_sp.order(:position)
                end

    show! do |format|
      @route = @route.decorate(context: {
                                 workbench: @workbench,
                                 referential: @referential,
                                 line: @line
                               })

      @route_sp = StopPointDecorator.decorate(@route_sp,
                                                context: {
                                                  workbench: @workbench
                                              })

      format.geojson { render 'routes/show.geo' }
    end
  end

  def destroy
    destroy! do |success, _failure|
      success.html { redirect_to workbench_referential_line_path(current_workbench, @referential, @line) }
    end
  end

  def create
    create! do |success, failure|
      failure.json do
        render json: { message: t('flash.actions.create.error', resource_name: t('activerecord.models.route.one')),
                       status: 422 }
      end
      success.json do
        render json: { message: t('flash.actions.create.notice', resource_name: t('activerecord.models.route.one')),
                       status: 200 }
      end
    end
  end

  def update
    update! do |success, failure|
      failure.json do
        render json: { message: t('flash.actions.update.error', resource_name: t('activerecord.models.route.one')),
                       status: 422 }
      end
      success.json do
        render json: { message: t('flash.actions.update.notice', resource_name: t('activerecord.models.route.one')) },
               status: :ok
      end
    end
  end

  def duplicate
    source = Chouette::Route.find(params[:id])
    route = source.duplicate params[:opposite]
    flash[:notice] = t('routes.duplicate.success')
    redirect_to workbench_referential_line_path(current_workbench, @referential, route.line)
  end

  def costs
    @route = resource
  end

  # React endpoints

  def fetch_user_permissions
    policy = policy(end_of_association_chain.new)
    perms = {
      'routes.create' => parent_policy.create?(Chouette::Route),
      'routes.update' => policy.update?,
      'routes.destroy' => policy.destroy?
    }

    render json: perms
  end

  def fetch_opposite_routes
    render json: { outbound: @backward, inbound: @forward }
  end

  protected

  alias route resource
  alias parent_for_parent_policy referential

  def collection
    @q = parent.routes.ransack(params[:q])
    @collection ||=
      begin
        routes = @q.result(distinct: true).order(:name)
        routes = routes.paginate(page: params[:page]) if @per_page.present?
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
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
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
      stop_points_attributes: %i[id _destroy position stop_area_id for_boarding for_alighting]
    )
  end
end
