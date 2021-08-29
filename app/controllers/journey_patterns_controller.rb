class JourneyPatternsController < ChouetteController
  include ReferentialSupport
  defaults :resource_class => Chouette::JourneyPattern

  respond_to :kml, :only => :show
  respond_to :json, :only => :available_specific_stop_places

  belongs_to :referential do
    belongs_to :line, :parent_class => Chouette::Line do
      belongs_to :route, :parent_class => Chouette::Route
    end
  end

  alias route parent
  alias journey_pattern resource

  include PolicyChecker

  def available_specific_stop_places
    render json: journey_pattern.available_specific_stop_places.map { |parent_id, children| [ parent_id, children.map { |s| s.as_json.merge("short_id" => s.get_objectid.short_id) } ] }.to_json, status: :ok
  end
end
