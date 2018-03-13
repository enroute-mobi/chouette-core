class StopAreasController < ChouetteController
  include ApplicationHelper
  include Activatable

  defaults :resource_class => Chouette::StopArea

  belongs_to :stop_area_referential
  # do
  #   belongs_to :line, :parent_class => Chouette::Line, :optional => true, :polymorphic => true
  #   belongs_to :network, :parent_class => Chouette::Network, :optional => true, :polymorphic => true
  #   belongs_to :connection_link, :parent_class => Chouette::ConnectionLink, :optional => true, :polymorphic => true
  # end

  respond_to :html, :kml, :xml, :json
  respond_to :js, :only => :index

  def autocomplete
    scope = stop_area_referential.stop_areas.where(deleted_at: nil)
    args  = [].tap{|arg| 4.times{arg << "%#{params[:q]}%"}}
    @stop_areas = scope.where("unaccent(name) ILIKE unaccent(?) OR unaccent(city_name) ILIKE unaccent(?) OR registration_number ILIKE ? OR objectid ILIKE ?", *args).limit(50)
    @stop_areas
  end

  def select_parent
    @stop_area = stop_area
    @parent = stop_area.parent
  end

  def add_children
    authorize stop_area
    @stop_area = stop_area
    @children = stop_area.children
  end

  def add_routing_lines
    @stop_area = stop_area
    @lines = stop_area.routing_lines
  end

  def add_routing_stops
    @stop_area = stop_area
  end

  def access_links
    @stop_area = stop_area
    @generic_access_links = stop_area.generic_access_link_matrix
    @detail_access_links = stop_area.detail_access_link_matrix
  end

  def index
    request.format.kml? ? @per_page = nil : @per_page = 12
    @zip_codes = stop_area_referential.stop_areas.where("zip_code is NOT null").distinct.pluck(:zip_code)

    index! do |format|
      format.html {
        # binding.pry
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_areas = StopAreaDecorator.decorate(@stop_areas)
      }
    end
  end

  def new
    authorize resource_class
    new!
  end

  def create
    authorize resource_class
    create!
  end

  def show
    show! do |format|
      unless stop_area.position or params[:default] or params[:routing]
        format.kml {
          render :nothing => true, :status => :not_found
        }

      end

      @stop_area = @stop_area.decorate
    end
  end

  def edit
    authorize stop_area
    super
  end

  def destroy
    authorize stop_area
    super
  end

  def update
    authorize stop_area
    update!
  end

  def default_geometry
    count = stop_area_referential.stop_areas.without_geometry.default_geometry!
    flash[:notice] = I18n.translate("stop_areas.default_geometry_success", :count => count)
    redirect_to stop_area_referential_stop_areas_path(@stop_area_referential)
  end

  def zip_codes
    respond_to do |format|
      format.json { render :json => referential.stop_areas.collect(&:zip_code).compact.uniq.to_json }
    end
  end

  protected

  alias_method :stop_area, :resource
  alias_method :stop_area_referential, :parent

  def collection
    scope = parent.present? ? parent.stop_areas : referential.stop_areas
    scope = ransack_status(scope)
    @q = scope.search(params[:q])

    if sort_column && sort_direction
      @stop_areas ||=
        begin
          stop_areas = @q.result.order(sort_column + ' ' + sort_direction)
          stop_areas = stop_areas.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
          stop_areas
        end
    else
      @stop_areas ||=
        begin
          stop_areas = @q.result.order(:name)
          stop_areas = stop_areas.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
          stop_areas
        end
    end
  end

  def begin_of_association_chain
    current_organisation
  end

  private

  def sort_column
    if parent.present?
      parent.stop_areas.column_names.include?(params[:sort]) ? params[:sort] : 'name'
    else
      referential.stop_areas.column_names.include?(params[:sort]) ? params[:sort] : 'name'
    end
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  alias_method :current_referential, :stop_area_referential
  helper_method :current_referential

  def stop_area_params
    fields = [
      :area_type,
      :children_ids,
      :city_name,
      :comment,
      :coordinates,
      :country_code,
      :fare_code,
      :int_user_needs,
      :latitude,
      :lift_availability,
      :long_lat_type,
      :longitude,
      :mobility_restricted_suitability,
      :name,
      :nearest_topic_name,
      :object_version,
      :objectid,
      :parent_id,
      :registration_number,
      :routing_line_ids,
      :routing_stop_ids,
      :stairs_availability,
      :street_name,
      :time_zone,
      :url,
      :waiting_time,
      :zip_code,
      :kind,
      :status,
      localized_names: Chouette::StopArea::AVAILABLE_LOCALIZATIONS
    ] + permitted_custom_fields_params(Chouette::StopArea.custom_fields) # XXX filter on the workgroup
    params.require(:stop_area).permit(fields)
  end

   # Fake ransack filter
  def ransack_status scope
    return scope unless params[:q].try(:[], :status)
    return scope if params[:q][:status].values.uniq.length == 1

    @status = {
      in_creation: params[:q][:status]['in_creation'] == 'true',
      confirmed: params[:q][:status]['confirmed'] == 'true',
      deactivated: params[:q][:status]['deactivated'] == 'true',
    }

    scope = Chouette::StopArea.where(
      "confirmed_at #{(@status[:confirmed] || @status[:deactivated]) ? "IS NOT NULL" : "IS NULL"}
      AND deleted_at #{@status[:deactivated] ? "IS NOT NULL" : "IS NULL"}"
      )

    params[:q].delete :status
    scope
  end
end
