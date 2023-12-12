module Types
  class RouteType < Types::BaseObject
    description "A Chouette Route"

    field :objectid, String, null: false
    field :name, String, null: true
    field :published_name, String, null: true
    field :wayback, String, null: true

    field :stop_areas, Types::StopAreaType.connection_type, null: false,
      description: "The Route's StopAreas"
    def stop_areas
      LazyLoading::RouteStopAreas.new(context, object.id)
    end
  end
end
