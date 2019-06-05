class ConnectionLinksController < ChouetteController
  include ApplicationHelper
  include Activatable
  include PolicyChecker

  defaults :resource_class => Chouette::ConnectionLink

  belongs_to :stop_area_referential

  respond_to :html

  def index
    index! do
      @connection_links = ConnectionLinkDecorator.decorate(@connection_links, context: { stop_area_referential: @stop_area_referential })
    end
  end

  def new
    @connection_link = Chouette::ConnectionLink.new(departure_id: params[:departure_id])
    new!
  end

  def create
    @connection_link = Chouette::ConnectionLink.new
    @connection_link.stop_area_referential = stop_area_referential
    @connection_link.assign_attributes connection_link_params
    create!
  end

  def show
    show! do
      @connection_link = @connection_link.decorate
    end
  end

  protected

  alias_method :connection_link, :resource
  alias_method :stop_area_referential, :parent

  def collection
    @q = parent.connection_links.search(params[:q])
    @connection_links ||= connection_links = @q.result(:distinct => true).includes(sort_param).order("#{sort_column} #{sort_direction}").paginate(:page => params[:page])
  end

  private

  def sort_param
    %w(departure arrival).include?(params[:sort]) ? params[:sort] : 'departure'
  end

  def sort_column
    return 'stop_areas.name' if params[:q].blank?
    sort_param == 'arrival' ? 'arrivals_connection_links_2.name' : 'departures_connection_links.name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  # alias_method :current_referential, :stop_area_referential
  # helper_method :current_referential

  def connection_link_params
    fields = [
      :departure_id,
      :objectid,
      :arrival_id,
      :object_version,
      :name,
      :comment,
      :link_distance,
      :connection_link_type,
      :default_duration_in_min,
      :frequent_traveller_duration_in_min,
      :occasional_traveller_duration_in_min,
      :mobility_restricted_traveller_duration_in_min,
      :mobility_restricted_suitability,
      :stairs_availability,
      :lift_availability,
      :int_user_needs,
      :created_at,
      :updated_at,
      :metadata,
      :both_ways
    ]
    params.require(:connection_link).permit(fields)
  end
end
