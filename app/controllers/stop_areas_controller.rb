class StopAreasController < ChouetteController
  include ApplicationHelper
  include Activatable

  defaults :resource_class => Chouette::StopArea

  belongs_to :workbench
  belongs_to :stop_area_referential, singleton: true

  respond_to :html, :kml, :geojson, :xml, :json
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

  def index
    request.format.kml? ? @per_page = nil : @per_page = 12
    @zip_codes = stop_area_referential.stop_areas.where("zip_code is NOT null").distinct.pluck(:zip_code)

    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @stop_areas = StopAreaDecorator.decorate(@stop_areas, context: { workbench: @workbench })
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

      format.geojson { render 'stop_areas/show.geo' }

      format.json do
        attributes = stop_area.attributes.slice(:id, :name, :objectid, :comment, :area_type, :registration_number, :longitude, :latitude, :long_lat_type, :country_code, :time_zone, :street_name, :kind, :custom_field_values, :metadata)
        area_type_label = I18n.t("area_types.label.#{stop_area.area_type}")
        attributes[:text] = "<span class='small label label-info'>#{area_type_label}</span>#{stop_area.full_name}"
        render json: attributes
      end

      @stop_area = @stop_area.decorate(context: { workbench: @workbench })
      @connection_links = ConnectionLinkDecorator.decorate(@stop_area.connection_links.limit(4), context: {workbench: @workbench})
    end
  end

  def fetch_connection_links
    @connection_links = []
    @connection_links = stop_area.connection_links if has_feature?(:stop_area_connection_links)

    respond_to do |format|
      format.geojson { render 'connection_links/index.geo' }
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

  def zip_codes
    respond_to do |format|
      format.json { render :json => referential.stop_areas.collect(&:zip_code).compact.uniq.to_json }
    end
  end

  protected

  alias_method :stop_area, :resource
  alias_method :stop_area_referential, :parent

  def build_resource
    get_resource_ivar || super.tap do |stop_area|
      stop_area.stop_area_provider ||= @workbench.default_stop_area_provider
    end
  end

  def collection
    scope = parent.present? ? parent.stop_areas : referential.stop_areas
    scope = is_referent_scope(scope)
    @q = scope.ransack(params[:q]&.except(:is_referent_true, :is_referent_false))

    @stop_areas ||=
      begin
        if sort_column == "area_type"
          sorted_area_type_labels = Chouette::AreaType.options.sort.transpose.last
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

  def is_referent_scope scope
    return scope unless params[:q]

    if params[:q][:is_referent_true] != params[:q][:is_referent_false]
      scope = scope.where(is_referent: (params[:q][:is_referent_true] == '1'))
    end

    scope
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
      :compass_bearing,
      :country_code,
      :fare_code,
      :referent_only,
      :is_referent,
      :latitude,
      :long_lat_type,
      :longitude,
      :mobility_impaired_accessibility,
      :wheelchair_accessibility,
      :step_free_accessibility,
      :escalator_free_accessibility,
      :lift_free_accessibility,
      :audible_signals_availability,
      :visual_signs_availability,
      :accessibility_limitation_description,
      :name,
      :public_code,
      :nearest_topic_name,
      :object_version,
      :objectid,
      :parent_id,
      :postal_region,
      :referent_id,
      :registration_number,
      :street_name,
      :time_zone,
      :url,
      :waiting_time,
      :zip_code,
      :kind,
      :status,
      :stop_area_provider_id,
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
      localized_names: stop_area_referential.locales.map{|l| l[:code]}
    ] + permitted_custom_fields_params(Chouette::StopArea.custom_fields(stop_area_referential.workgroup))
    params.require(:stop_area).permit(fields)
  end
end
