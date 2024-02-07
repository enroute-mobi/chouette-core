# frozen_string_literal: true

class RouteVehicleJourneysController < Chouette::ReferentialController
  defaults resource_class: Chouette::VehicleJourney
  belongs_to :route, parent_class: Chouette::Route
  alias_method :route, :parent
  alias_method :vehicle_journeys, :collection

  skip_after_action :set_modifier_metadata
  before_action :user_permissions, only: :show

  def show # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    respond_to do |format|
      if collection.out_of_bounds?
        redirect_to params.merge(:page => 1)
      end
      format.json do
        @vehicle_journeys = @vehicle_journeys.includes(stop_points: :stop_area)
      end
      format.html do
        load_missions
        load_custom_fields
        @stop_points_list = map_stop_points(route.stop_points)
        @return_stop_points_list = map_stop_points(route.opposite_route&.stop_points) if has_feature?(:vehicle_journeys_return_route)
        @transport_mode = route.line['transport_mode']
        @transport_submode = route.line['transport_submode']

        if params[:jp]
          @jp_origin  = Chouette::JourneyPattern.find_by(objectid: params[:jp])
          @jp_origin_stop_points = map_stop_points(@jp_origin.stop_points)
        end
      end
    end
  end

  def update
    state = JSON.parse request.raw_post
    @resources = Chouette::VehicleJourney.state_update route, state
    errors = state.any? { |item| item['errors'] }

    respond_to do |format|
      format.json do
        render json: state, status: errors ? :unprocessable_entity : :ok
      end
    end
  end

  protected

  def collection
    scope = route.vehicle_journeys.with_stops
    scope = maybe_filter_by_departure_time(scope)
    scope = maybe_filter_out_journeys_with_time_tables(scope)

    @vehicle_journeys ||= begin
      @q = scope.ransack filtered_ransack_params

      @ppage = 20
      vehicle_journeys = @q.result.paginate(:page => params[:page], :per_page => @ppage)
      @footnotes = route.line.footnotes.map { |f| f.attributes.slice(*%w[label id code]) }
      route.line.line_notices.each do |line_notice|
        @footnotes << {
          code: line_notice.title,
          label: helpers.truncate(line_notice.content, length: 120),
          id: line_notice.id,
          line_notice: true
        }
      end
      @footnotes = @footnotes.to_json
      @matrix    = resource_class.matrix(vehicle_journeys)
      vehicle_journeys
    end
  end
  alias resource collection

  def maybe_filter_by_departure_time(scope)
    if params[:q] &&
        params[:q][:vehicle_journey_at_stops_departure_time_gteq] &&
        params[:q][:vehicle_journey_at_stops_departure_time_lteq]
      scope = scope.where_departure_time_between(
        params[:q][:vehicle_journey_at_stops_departure_time_gteq],
        params[:q][:vehicle_journey_at_stops_departure_time_lteq],
        allow_empty:
          params[:q][:vehicle_journey_without_departure_time] == 'true'
      )
    end

    scope
  end

  def maybe_filter_out_journeys_with_time_tables(scope)
    if params[:q] && params[:q][:vehicle_journey_without_time_table] == 'false'
      return scope.without_time_tables
    end

    scope
  end

  def filtered_ransack_params
    if params[:q]
      params[:q] = params[:q].reject { |k| params[:q][k] == 'undefined' }
      params[:q].except(:vehicle_journey_at_stops_departure_time_gteq, :vehicle_journey_at_stops_departure_time_lteq)
    end
  end

  def user_permissions
    @features = Hash[*current_organisation.features.map { |f| [f, true] }.flatten].to_json
    @perms = %w[create destroy update].inject({}) do |permissions, action|
      permissions.merge("vehicle_journeys.#{action}" => resource_policy.authorizes_action?(action))
    end.to_json
  end

  private

  def load_custom_fields
    @custom_fields = Chouette::VehicleJourney.custom_fields_definitions(referential.workgroup)

    @extra_headers = Rails.application.config.vehicle_journeys_extra_headers.dup.delete_if do |header|
      header[:type] == :custom_field and not @custom_fields.has_key?(header[:name].to_s)
    end
  end

  def map_stop_points points
    (points&.includes(:stop_area) || []).map do |sp|
      {
        :id => sp.stop_area.id,
        :route_id => sp.try(:route_id),
        :object_id => sp.try(:objectid),
        :area_object_id => sp.stop_area.try(:objectid),
        :position => sp.try(:position),
        :for_boarding => sp.try(:for_boarding),
        :for_alighting => sp.try(:for_alighting),
        :name => sp.stop_area.try(:name),
        :time_zone_offset => sp.stop_area.try(:time_zone_offset),
        :time_zone_formatted_offset => sp.stop_area.try(:time_zone_formatted_offset),
        :zip_code => sp.stop_area.try(:zip_code),
        :city_name => sp.stop_area.try(:city_name),
        :comment => sp.stop_area.try(:comment),
        :area_type => sp.stop_area.try(:area_type),
        :area_type_i18n => I18n.t(sp.stop_area.try(:area_type), scope: 'area_types.label'),
        :area_kind => sp.stop_area.try(:kind),
        :stop_area_id => sp.stop_area_id,
        :registration_number => sp.stop_area.try(:registration_number),
        :nearest_topic_name => sp.stop_area.try(:nearest_topic_name),
        :longitude => sp.stop_area.try(:longitude),
        :latitude => sp.stop_area.try(:latitude),
        :long_lat_type => sp.stop_area.try(:long_lat_type),
        :country_code => sp.stop_area.try(:country_code),
        :country_name => sp.stop_area.try(:country_name),
        :street_name => sp.stop_area.try(:street_name),
        :waiting_time => sp.stop_area.try(:waiting_time),
        :waiting_time_text => sp.stop_area.decorate.try(:waiting_time_text),
      }
    end
  end

  def load_missions
    @all_missions = route.journey_patterns.count > 10 ? [] : route.journey_patterns.map do |item|
      published_name = ERB::Util.h(item.published_name)
      short_id = ERB::Util.h(item.get_objectid.short_id)
      registration_number = ERB::Util.h(item.registration_number)
      {
        id: item.id,
        "data-item": {
          id: item.id,
          name: item.name,
          published_name: item.published_name,
          object_id: item.objectid,
          short_id: item.get_objectid.short_id,
          full_schedule: item.full_schedule?,
          costs: item.costs,
          journey_length: item.journey_length,
          stop_area_short_descriptions: item.stop_points.map do |stop|
            {
              stop_area_short_description: {
                position: stop.position,
                id: stop.stop_area_id,
                name: stop.stop_area.name,
                object_id: stop.stop_area.objectid
              }
            }
          end,
          stop_points: item.stop_points.map do |sp|
            {
              id: sp.id,
              name: sp.name,
              objectid: sp.objectid,
              stop_area_id: sp.stop_area_id
            }
          end
        }.to_json,
        text: "<strong>#{published_name} - #{short_id}</strong><br/><small>#{registration_number}</small>"
      }
    end
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
