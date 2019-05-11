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

  # def default_geometry
  #   count = stop_area_referential.stop_areas.without_geometry.default_geometry!
  #   flash[:notice] = I18n.translate("stop_areas.default_geometry_success", :count => count)
  #   redirect_to stop_area_referential_stop_areas_path(@stop_area_referential)
  # end

  # def zip_codes
  #   respond_to do |format|
  #     format.json { render :json => referential.stop_areas.collect(&:zip_code).compact.uniq.to_json }
  #   end
  # end

  protected

  alias_method :connection_link, :resource
  alias_method :stop_area_referential, :parent

  def collection
    @q = parent.connection_links.search(params[:q])
    @connection_links ||=
      begin
        connection_links = @q.result(:distinct => true).order(:name)
        connection_links = connection_links.paginate(:page => params[:page]) if @per_page.present?
        connection_links
      end
    @connection_links ||= parent.connection_links
  end

  # def collection
  #   scope = parent.present? ? parent.connection_links : referential.connection_links
  #   @q = scope.search(params[:q])

  #   @connection_links ||=
  #     begin
  #       # if sort_column == "area_type"
  #       #   sorted_area_type_labels = Chouette::AreaType.options(:all, I18n.locale).sort.transpose.last
  #       #   sorted_area_type_labels = sorted_area_type_labels.reverse if sort_direction != 'asc'
  #       #   order_by = ["CASE"]
  #       #   sorted_area_type_labels.each_with_index do |area_type, index|
  #       #     order_by << "WHEN area_type='#{area_type}' THEN #{index}"
  #       #   end
  #       #   order_by << "END"
  #       #   connection_links = @q.result.order(order_by.join(" "))
  #       # else
  #         connection_links = sort_result(@q.result)
  #       # end
  #       connection_links = connection_links.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
  #       connection_links
  #     end
  # end

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
     # + permitted_custom_fields_params(Chouette::StopArea.custom_fields(stop_area_referential.workgroup))
    params.require(:connection_link).permit(fields)
  end
end
