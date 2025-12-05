# frozen_string_literal: true

class ConnectionLinksController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  defaults :resource_class => Chouette::ConnectionLink

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show get_connection_speeds]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html, :geojson

  def index
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search(Search::ConnectionLink.attributes_from_params(params))
    end

    index! do
      @connection_links = ConnectionLinkDecorator.decorate(
        @connection_links.includes(:departure, :arrival, :stop_area_provider),
        context: { workbench: workbench }
      )
    end
  end

  def show
    show! do |format|
      @connection_link = @connection_link.decorate context: { workbench: workbench }

      format.geojson { render 'connection_links/show' }
    end
  end

  def get_connection_speeds
    render json: { connectionSpeed: Rails.application.config.connection_speeds }
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(Search::ConnectionLink)
  end

  protected

  alias_method :connection_link, :resource

  def build_resource
    get_resource_ivar || super.tap do |connection_link|
      connection_link.departure_id ||= params[:departure_id]
      connection_link.stop_area_provider ||= workbench.default_stop_area_provider
    end
  end

  def scope
    parent.connection_links
  end

  def search
    @search ||= ::Search::ConnectionLink.from_params(params, workbench: workbench)
  end

  def collection
    @connection_links ||= search.search(scope) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  private

  def connection_link_params
    return @connection_link_params if @connection_link_params

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
      :both_ways,
      :stop_area_provider_id
    ]
    @connection_link_params = params.require(:connection_link).permit(fields)
  end
end
