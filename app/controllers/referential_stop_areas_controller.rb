# -*- coding: utf-8 -*-
class ReferentialStopAreasController  < ChouetteController
  include ReferentialSupport
  defaults :resource_class => Chouette::StopArea, :collection_name => 'stop_areas', :instance_name => 'stop_area'

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line, :optional => true, :polymorphic => true
    belongs_to :network, :parent_class => Chouette::Network, :optional => true, :polymorphic => true
  end

  respond_to :html, :kml, :xml, :json
  respond_to :js, :only => :index

  def select_parent
    @stop_area = stop_area
    @parent = stop_area.parent
  end

  def add_children
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
    @zip_codes = referential.stop_areas.where("zip_code is NOT null").distinct.pluck(:zip_code)
    index! do |format|
      format.html {
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end
      }
    end
  end

  def new
    new!
  end

  def create
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
    edit! do
      stop_area.position ||= stop_area.default_position
   end
  end

  def update
    stop_area.position ||= stop_area.default_position

    update!
  end

  def default_geometry
    count = referential.stop_areas.without_geometry.default_geometry!
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

  def collection
    @q = parent.present? ? parent.stop_areas.search(params[:q]) : referential.stop_areas.search(params[:q])

    if sort_column && sort_direction
      @stop_areas ||=
        begin
          stop_areas = @q.result(:distinct => true).order(sort_column + ' ' + sort_direction)
          stop_areas = stop_areas.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
          stop_areas
        end
    else
      @stop_areas ||=
        begin
          stop_areas = @q.result(:distinct => true).order(:name)
          stop_areas = stop_areas.paginate(:page => params[:page], :per_page => @per_page) if @per_page.present?
          stop_areas
        end
    end
  end

  private

  def sort_column
    if parent.present?
      parent.stop_areas.include?(params[:sort]) ? params[:sort] : 'name'
    else
      referential.stop_areas.include?(params[:sort]) ? params[:sort] : 'name'
    end
  end
  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def stop_area_params
    params.require(:stop_area).permit( :routing_stop_ids, :routing_line_ids, :children_ids, :stop_area_type, :parent_id, :objectid, :object_version, :name, :comment, :area_type, :registration_number, :nearest_topic_name, :fare_code, :longitude, :latitude, :long_lat_type, :country_code, :street_name, :zip_code, :city_name, :mobility_restricted_suitability, :stairs_availability, :lift_availability, :int_user_needs, :coordinates, :url, :time_zone )
  end

end
