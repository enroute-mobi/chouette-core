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
        load_footnotes
        load_matrix
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
    errors = state.any? { |item| item['errors'] || item['vehicle_journey_at_stops'].any? { |vjas| vjas['errors'] } }

    respond_to do |format|
      format.json do
        render json: state, status: errors ? :unprocessable_entity : :ok
      end
    end
  end

  protected

  def scope
    parent.vehicle_journeys.with_stops # .with_stops orders the result
  end

  def search
    @search ||= Search::VehicleJourney.from_params(params, referential: referential, per_page: 20).without_order
  end

  def collection
    @vehicle_journeys ||= search.search(scope) # rubocop:disable Naming/MemoizedInstanceVariableName
  end
  alias resource collection

  def user_permissions
    @features = Hash[*current_organisation.features.map { |f| [f, true] }.flatten].to_json
    @perms = {
      'vehicle_journeys.create' => parent_policy.create?(Chouette::VehicleJourney),
      'vehicle_journeys.update' => resource_policy.update?,
      'vehicle_journeys.destroy' => resource_policy.destroy?
    }.to_json
  end

  private

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
        :flexible => sp.try(:flexible),
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
        :longitude => sp.stop_area.try(:longitude),
        :latitude => sp.stop_area.try(:latitude),
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

  def load_footnotes
    @footnotes =
      route.line.footnotes.map { |f| f.attributes.slice(*%w[label id code]) } + \
      route.line.line_notices.map do |line_notice|
        {
          code: line_notice.title,
          label: helpers.truncate(line_notice.content, length: 120),
          id: line_notice.id,
          line_notice: true
        }
      end
  end

  def load_matrix
    @matrix = resource_class.matrix(collection)
  end
end
