class VehicleJourneysController < ChouetteController
  include ReferentialSupport
  defaults :resource_class => Chouette::VehicleJourney
  before_action :user_permissions, only: :index

  respond_to :json, :only => :index
  respond_to :js, :only => [:select_journey_pattern, :select_vehicle_journey, :edit, :new, :index]

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line do
      belongs_to :route, :parent_class => Chouette::Route
    end
  end

  include PolicyChecker
  alias_method :vehicle_journeys, :collection
  alias_method :route, :parent
  alias_method :vehicle_journey, :resource

  def select_journey_pattern
    if params[:journey_pattern_id]
      selected_journey_pattern = Chouette::JourneyPattern.find(params[:journey_pattern_id])

      @vehicle_journey = vehicle_journey
      @vehicle_journey.update_journey_pattern(selected_journey_pattern)
    end
  end
  def select_vehicle_journey
    if params[:vehicle_journey_objectid]
      @vehicle_journey = Chouette::VehicleJourney.find(params[:vehicle_journey_objectid])
    end
  end

  def create
    create!(:alert => t('activerecord.errors.models.vehicle_journey.invalid_times'))
  end

  def update
    update!(:alert => t('activerecord.errors.models.vehicle_journey.invalid_times'))
  end

  def index
    index! do |format|
      if collection.out_of_bounds?
        redirect_to params.merge(:page => 1)
      end
      format.json do
        @vehicle_journeys = @vehicle_journeys.includes({stop_points: :stop_area})
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
          @jp_origin_stop_points = @jp_origin.stop_points
        end
      end
    end
  end

  # overwrite inherited resources to use delete instead of destroy
  # foreign keys will propagate deletion)
  def destroy_resource(object)
    object.delete
  end

  protected
  def collection
    scope = route.vehicle_journeys.with_stops
    scope = maybe_filter_by_departure_time(scope)
    scope = maybe_filter_out_journeys_with_time_tables(scope)

    @vehicle_journeys ||= begin
      @q = scope.search filtered_ransack_params

      @ppage = 20
      vehicle_journeys = @q.result.paginate(:page => params[:page], :per_page => @ppage)
      @footnotes = route.line.footnotes.to_json
      @matrix    = resource_class.matrix(vehicle_journeys)
      vehicle_journeys
    end
  end

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

    # if params[:q]
    #   if params[:q][:vehicle_journey_without_time_table] == 'true'
    #     return scope.without_time_tables
    #   end
    # else
    #   return scope.without_time_tables
    # end

    scope
  end

  def filtered_ransack_params
    if params[:q]
      params[:q] = params[:q].reject{|k| params[:q][k] == 'undefined'}
      params[:q].except(:vehicle_journey_at_stops_departure_time_gteq, :vehicle_journey_at_stops_departure_time_lteq)
    end
  end

  def adapted_params
    params.tap do |adapted_params|
      adapted_params.merge!(:route => parent)
      hour_entry = "vehicle_journey_at_stops_departure_time_gt(4i)".to_sym
      if params[:q] && params[:q][ hour_entry]
        adapted_params[:q].merge! hour_entry => (params[:q][ hour_entry].to_i - utc_offset)
      end
    end
  end
  def utc_offset
    # Ransack Time eval - utc eval
    sample = [2001,1,1,10,0]
    Time.zone.local(*sample).utc.hour - Time.utc(*sample).hour
  end

  def matrix
    @matrix = resource_class.matrix(@vehicle_journeys)
  end

  def user_permissions
    @features = Hash[*current_organisation.features.map{|f| [f, true]}.flatten].to_json
    policy = policy(:vehicle_journey)
    @perms =
      %w{create destroy update}.inject({}) do | permissions, action |
        permissions.merge( "vehicle_journeys.#{action}" => policy.authorizes_action?(action) )
      end.to_json
  end

  private
  def load_custom_fields
    @custom_fields = referential.workgroup&.custom_fields_definitions || {}
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
        :fare_code => sp.stop_area.try(:fare_code),
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
          stop_area_short_descriptions: item.stop_areas.map do |stop|
            {
              stop_area_short_description: {
                id: stop.id,
                name: stop.name,
                object_id: item.objectid
              }
            }
          end
        }.to_json,
        text: "<strong>#{item.published_name} - #{item.get_objectid.short_id}</strong><br/><small>#{item.registration_number}</small>"
      }
    end
  end
  def vehicle_journey_params
    params.require(:vehicle_journey).permit(
      { footnote_ids: [] },
      :journey_pattern_id,
      :number,
      :published_journey_name,
      :published_journey_identifier,
      :comment,
      :transport_mode,
      :mobility_restricted_suitability,
      :flexible_service,
      :status_value,
      :facility,
      :vehicle_type_identifier,
      :objectid,
      :time_table_tokens,
      { date: [:hour, :minute] },
      :button,
      :referential_id,
      :line_id,
      :route_id,
      :id,
      { vehicle_journey_at_stops_attributes: [:arrival_time, :id, :_destroy, :stop_point_id, :departure_time] }
    )
  end
end
