# frozen_string_literal: true

class StopAreasController < Chouette::StopAreaReferentialController
  include ApplicationHelper

  defaults :resource_class => Chouette::StopArea

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show autocomplete fetch_connection_links]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html, :geojson, :xml, :json
  respond_to :js, :only => :index

  def autocomplete
    scope = stop_area_referential.stop_areas.where(deleted_at: nil)
    scope = scope.referent_only if params[:referent_only]

    text = params[:q]&.strip
    @stop_areas = text.present? ? scope.by_text(text).limit(50) : Chouette::StopArea.none
  end

  def index # rubocop:disable Metrics/MethodLength
    if saved_search = saved_searches.find_by(id: params[:search_id])
      @search = saved_search.search
    end

    @per_page = 25
    @zip_codes = stop_area_referential.stop_areas.where("zip_code is NOT null").distinct.pluck(:zip_code)

    index! do |format|
      format.html {
        @stop_areas = StopAreaDecorator.decorate(
          collection,
          context: {
            workbench: workbench
          }
        )
      }
    end
  end

  def show # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    show! do |format|
      format.geojson { render 'stop_areas/show.geo' }

      format.json do
        attributes = stop_area.attributes.slice(:id, :name, :objectid, :comment, :area_type, :registration_number, :longitude, :latitude, :long_lat_type, :country_code, :time_zone, :street_name, :kind, :custom_field_values, :metadata)
        area_type_label = I18n.t("area_types.label.#{stop_area.area_type}")
        attributes[:text] = "<span class='small label label-info'>#{area_type_label}</span>#{stop_area.full_name}"
        render json: attributes
      end

      @stop_area = @stop_area.decorate(context: { workbench: workbench })
      @connection_links = ConnectionLinkDecorator.decorate(
        @stop_area.connection_links.limit(4),
        context: {
          workbench: workbench
        }
      )
    end
  end

  def fetch_connection_links
    @connection_links = []
    @connection_links = stop_area.connection_links if has_feature?(:stop_area_connection_links)

    respond_to do |format|
      format.geojson { render 'connection_links/index.geo' }
    end
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(Search::StopArea)
  end

  protected

  alias_method :stop_area, :resource

  def scope
    parent.stop_areas
  end

  def search
    @search ||= Search::StopArea.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def stop_area_params
    return @stop_area_params if @stop_area_params

    fields = [
      :area_type,
      :children_ids,
      :city_name,
      :comment,
      :coordinates,
      :compass_bearing,
      :country_code,
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
      :transport_mode,
      fare_zone_ids: [],
      codes_attributes: [:id, :code_space_id, :value, :_destroy],
      localized_names: stop_area_referential.locales.map{|l| l[:code]}
    ] + permitted_custom_fields_params(Chouette::StopArea.custom_fields(stop_area_referential.workgroup))
    @stop_area_params = params.require(:stop_area).permit(fields)
  end
end
