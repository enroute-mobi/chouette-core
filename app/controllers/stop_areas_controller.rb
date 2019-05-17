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
    scope = scope.referent_only if params[:referent_only]
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
    @stop_area = Chouette::StopArea.new
    @stop_area.stop_area_referential = stop_area_referential
    @stop_area.assign_attributes stop_area_params
    create!
  end

  def show
    show! do |format|
      unless stop_area.position or params[:default] or params[:routing]
        format.kml {
          render :nothing => true, :status => :not_found
        }
      end
      format.json do
        attributes = stop_area.attributes.slice(*%w(id name objectid comment area_type registration_number longitude latitude long_lat_type country_code time_zone street_name kind custom_field_values metadata))
        attributes[:text] = "<span class='small label label-info'>#{I18n.t("area_types.label.#{stop_area.area_type}")}</span>#{stop_area.full_name}"
        render json: attributes
      end

      @stop_area = @stop_area.decorate
      @specific_stops = @stop_area.specific_stops.paginate(:page => params[:page], :per_page => 5)
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
    @q = scope.ransack(params[:q])

    @stop_areas ||=
      begin
        if sort_column == "area_type"
          sorted_area_type_labels = Chouette::AreaType.options(:all, I18n.locale).sort.transpose.last
          sorted_area_type_labels = sorted_area_type_labels.reverse if sort_direction != 'asc'
          order_by = ["CASE"]
          sorted_area_type_labels.each_with_index do |area_type, index|
            order_by << "WHEN area_type='#{area_type}' THEN #{index}"
          end
          order_by << "END"
          stop_areas = @q.result.order(order_by.join(" "))
        else
          stop_areas = sort_result(@q.result)
        end
        stop_areas = stop_areas.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
        stop_areas
      end
  end

  private

  def sort_column
    ref = parent.present? ? parent : referential
    (ref.stop_areas.column_names + %w{status}).include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def sort_result collection
    col_names = parent.present? ? parent.stop_areas.column_names : referential.stop_areas.column_names
    col = (col_names + %w{status}).include?(params[:sort]) ? params[:sort] : 'name'

    if ['status'].include?(col)
      collection.send("order_by_#{col}", sort_direction)
    else
      collection.order("#{col} #{sort_direction}")
    end
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
      :referent_only,
      :int_user_needs,
      :is_referent,
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
      :referent_id,
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
      localized_names: Chouette::StopArea::AVAILABLE_LOCALIZATIONS,
      stop_area_provider_ids: []
    ] + permitted_custom_fields_params(Chouette::StopArea.custom_fields(stop_area_referential.workgroup))
    params.require(:stop_area).permit(fields)
  end
end
