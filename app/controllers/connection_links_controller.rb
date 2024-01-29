# frozen_string_literal: true

class ConnectionLinksController < Chouette::StopAreaReferentialController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Chouette::ConnectionLink

  respond_to :html, :geojson

  def index
    index! do
      @connection_links = ConnectionLinkDecorator.decorate(@connection_links, context: { workbench: workbench })
    end
  end

  def show
    show! do |format|
      @connection_link = @connection_link.decorate context: { workbench: workbench }

      format.geojson { render 'connection_links/show.geo' }
    end
  end

  def get_connection_speeds
    render json: { connectionSpeed: Rails.application.config.connection_speeds }
  end

  protected

  alias_method :connection_link, :resource

  def build_resource
    get_resource_ivar || super.tap do |connection_link|
      connection_link.departure_id ||= params[:departure_id]
      connection_link.stop_area_provider ||= workbench.default_stop_area_provider
    end
  end

  def collection
    @q = parent.connection_links.search(params[:q])
    @connection_links ||= if sort_column == 'departure'
      @q.result.joins('INNER JOIN public.stop_areas departures ON departures.id = connection_links.departure_id').order("departures.name #{sort_direction}").paginate(:page => params[:page])
    else
      @q.result.joins('INNER JOIN public.stop_areas arrivals ON arrivals.id = connection_links.arrival_id').order("arrivals.name #{sort_direction}").paginate(:page => params[:page])
    end
  end

  private

  def sort_column
    params[:sort].presence || 'departure'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end


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
