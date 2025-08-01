# frozen_string_literal: true

class JourneyPatternsController < Chouette::ReferentialController
  defaults :resource_class => Chouette::JourneyPattern

  respond_to :json, :only => :available_specific_stop_places

  belongs_to :line, parent_class: Chouette::Line
  belongs_to :route, parent_class: Chouette::Route

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[
    new create index show
    new_vehicle_journey
    available_specific_stop_places
  ]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  alias route parent
  alias journey_pattern resource

  def available_specific_stop_places
    render json: journey_pattern.available_specific_stop_places.map { |parent_id, children| [ parent_id, children.map { |s| s.as_json.merge("short_id" => s.get_objectid.short_id) } ] }.to_json, status: :ok
  end

  def unassociate_shape
    journey_pattern.update(shape: nil)
    render json: {}
  end

  def duplicate
    journey_pattern.duplicate!
    render json: {}
  end
end
