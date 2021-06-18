class ShapeEditorController < ApplicationController
  before_action :referential_switch

  def home
  end

  def get_journey_patterns
    route = Chouette::Route.find(params.fetch(:route_id))

    options = route.journey_patterns.map do |jp|
      {
        value: jp.id,
        label: jp.published_name
      }
    end
  
    render json: options
  end

  def update_line
    coordinates = JSON.parse(request.raw_post).fetch('coordinates')

    render json: TomTom::BuildLineStringFeature.call(coordinates)
  end

  private

  def referential_switch
    Referential.find(params.fetch(:referential_id)).switch
  end
end
