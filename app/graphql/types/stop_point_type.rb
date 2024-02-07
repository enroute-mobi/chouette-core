module Types
  class StopPointType < Types::BaseObject
    description 'A Chouette StopPoint'

    field :objectid, String, null: false
    field :position, String, null: false
    field :for_boarding, String, null: true
    field :for_alighting, String, null: true

    field :route, Types::RouteType, null: false, description: "The StopPoint's Route"
    def route
      LazyLoading::Routes.new(context, object.route_id)
    end

    field :stop_area, Types::StopAreaType, null: false, description: "The StopPoint's StopArea"
    def stop_area
      LazyLoading::StopRelation.new(context, object.stop_area_id)
    end
  end
end
