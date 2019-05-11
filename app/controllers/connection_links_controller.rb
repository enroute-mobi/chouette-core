class ConnectionLinksController < ChouetteController
  include ApplicationHelper
  include Activatable

  defaults :resource_class => Chouette::ConnectionLink

  belongs_to :stop_area_referential

  respond_to :html

  def index
    index! do
      @connection_links = ConnectionLinkDecorator.decorate(@connection_links)
    end
  end

  def new
    authorize resource_class
    new!
  end

  def create
    authorize resource_class
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

  def edit
    authorize connection_link
    super
  end

  def destroy
    authorize connection_link
    super
  end

  def update
    authorize connection_link
    update!
  end

  protected

  alias_method :connection_link, :resource
  alias_method :stop_area_referential, :parent

  def collection
    @q = parent.connection_links.search(params[:q])
    @connection_links ||=
      begin
        connection_links = @q.result(:distinct => true).order(:name)
        connection_links = connection_links.paginate(:page => params[:page])
        connection_links
      end
    @connection_links ||= parent.connection_links
  end

  private

  # def sort_column
  #   ref = parent.present? ? parent : referential
  #   (ref.stop_areas.column_names + %w{status}).include?(params[:sort]) ? params[:sort] : 'name'
  # end

  # def sort_direction
  #   %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  # end

  # def sort_result collection
  #   col_names = parent.present? ? parent.stop_areas.column_names : referential.stop_areas.column_names
  #   col = (col_names + %w{status}).include?(params[:sort]) ? params[:sort] : 'name'

  #   if ['status'].include?(col)
  #     collection.send("order_by_#{col}", sort_direction)
  #   else
  #     collection.order("#{col} #{sort_direction}")
  #   end
  # end

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
      :link_type,
      :default_duration,
      :frequent_traveller_duration,
      :occasional_traveller_duration,
      :mobility_restricted_traveller_duration,
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
