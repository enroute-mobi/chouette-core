class JourneyPatternsController < ChouetteController
  include ReferentialSupport
  defaults :resource_class => Chouette::JourneyPattern

  respond_to :kml, :only => :show
  respond_to :json, :only => :available_specific_stop_places
  respond_to :geojson, only: :show

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line do
      belongs_to :route, :parent_class => Chouette::Route
    end
  end

  alias route parent
  alias journey_pattern resource

  include PolicyChecker

  def index
    index! do |format|
      format.html { redirect_to referential_line_route_path(@referential,@line,@route) }
    end
  end

  def create_resource(object)
    object.special_update
  end

  def show
    @stop_points = journey_pattern.stop_points.paginate(:page => params[:page])
    show! do |format|
      format.geojson { render 'journey_patterns/show.geo' }
    end
  end

  def new_vehicle_journey
    @vehicle_journey = Chouette::VehicleJourney.new(:route_id => route.id)
    @vehicle_journey.update_journey_pattern(resource)
    vehicle_journey_category = params[:journey_category] ? "vehicle_journey_#{params[:journey_category]}" : 'vehicle_journey'
    render "#{vehicle_journey_category.pluralize}/select_journey_pattern"
  end

  def available_specific_stop_places
    render json: journey_pattern.available_specific_stop_places.map { |parent_id, children| [ parent_id, children.map { |s| s.as_json.merge("short_id" => s.get_objectid.short_id) } ] }.to_json, status: :ok
  end

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion)
  def destroy_resource(object)
    object.delete
  end

  def collection
    @q = route.journey_patterns.ransack( params[:q])
    @journey_patterns ||= @q.result(:distinct => true).order(:name)
  end

  def unassociate_shape
    journey_pattern.update(shape: nil)

    response.set_header('Location', referential_line_route_journey_patterns_collection_path(@referential, @line, @route))
  end

  def duplicate
    journey_pattern.duplicate!

    response.set_header('Location', referential_line_route_journey_patterns_collection_path(@referential, @line, @route))

    render json: {}
  end

  private

  def journey_pattern_params
    params.require(:journey_pattern).permit(:route_id, :objectid, :object_version, :name, :comment, :registration_number, :published_name, :departure_stop_point_id, :arrival_stop_point_id, {:stop_point_ids => []})
  end

end
