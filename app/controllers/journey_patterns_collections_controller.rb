# frozen_string_literal: true

class JourneyPatternsCollectionsController < Chouette::ReferentialController
  defaults :resource_class => Chouette::JourneyPattern
  before_action :user_permissions, only: :show
  skip_after_action :set_modifier_metadata

  respond_to :html
  respond_to :json

  belongs_to :line, parent_class: Chouette::Line
  belongs_to :route, parent_class: Chouette::Route

  alias_method :vehicle_journeys, :collection
  alias_method :route, :parent
  alias_method :vehicle_journey, :resource

  def show
    @q = route.journey_patterns
    if params[:q].present?
      ids = @q.ransack(params[:q]).result(distinct: true).pluck(:id)
      @q = @q.where(id: ids)
    end
    @q = @q.includes(:stop_points)
    @ppage = 10
    @journey_patterns ||= @q.paginate(page: params[:page], per_page: @ppage).order(:name)
    @custom_fields = Chouette::JourneyPattern.custom_fields_definitions(referential.workgroup)

    respond_to do |format|
      format.json do
        @journey_patterns = @journey_patterns.includes(stop_points: {stop_area: :stop_area_referential})
      end
      format.html do
        @stop_points_list = []
        route.stop_points.includes(:stop_area).each do |sp|
          @stop_points_list << {
            :id => sp.stop_area.id,
            :route_id => sp.try(:route_id),
            :object_id => sp.try(:objectid),
            :stop_area_object_id => sp.stop_area.try(:objectid),
            :position => sp.try(:position),
            :for_boarding => sp.try(:for_boarding),
            :for_alighting => sp.try(:for_alighting),
            :name => sp.stop_area.try(:name),
            :zip_code => sp.stop_area.try(:zip_code),
            :city_name => sp.stop_area.try(:city_name),
            :country_name => sp.stop_area.try(:country_name),
            :time_zone_formatted_offset => sp.stop_area.try(:time_zone_formatted_offset),
            :comment => sp.stop_area.try(:comment),
            :area_type => sp.stop_area.try(:area_type),
            :registration_number => sp.stop_area.try(:registration_number),
            :nearest_topic_name => sp.stop_area.try(:nearest_topic_name),
            :longitude => sp.stop_area.try(:longitude),
            :latitude => sp.stop_area.try(:latitude),
            :long_lat_type => sp.stop_area.try(:long_lat_type),
            :country_code => sp.stop_area.try(:country_code),
            :street_name => sp.stop_area.try(:street_name)
          }
        end
        @stop_points_list = @stop_points_list.sort_by {|a| a[:position] }
      end
    end
  end

  def update
    state  = JSON.parse request.raw_post
    Chouette::JourneyPattern.state_update route, state
    @resources = route.journey_patterns
    errors = state.any? {|item| item['errors']}

    respond_to do |format|
      format.json { render json: state, status: errors ? :unprocessable_entity : :ok }
    end
  end

  protected

  def user_permissions
    @features = Hash[*current_organisation.features.map{|f| [f, true]}.flatten].to_json
    policy = policy(:journey_pattern)
    @perms =
      %w{create destroy update}.inject({}) do | permissions, action |
        permissions.merge( "journey_patterns.#{action}" => policy.authorizes_action?(action) )
      end.to_json
  end
end
