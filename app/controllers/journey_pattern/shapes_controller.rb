module JourneyPattern
  class ShapesController < ChouetteController
    include ReferentialSupport
    
    defaults singleton: true, resource_class: Shape

    belongs_to :referential
    belongs_to :line, parent_class: Chouette::Line
    belongs_to :route, parent_class: Chouette::Route
    belongs_to :journey_pattern, parent_class: Chouette::JourneyPattern

    def update_line
      coordinates = JSON.parse(request.raw_post).fetch('coordinates')

      render json: TomTom::BuildLineStringFeature.call(coordinates)
    end
  end
end