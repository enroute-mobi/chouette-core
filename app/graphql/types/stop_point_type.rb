module Types
  class StopPointType < Types::BaseObject
    description 'A Chouette StopPoint'

    field :objectid, String, null: false
    field :position, Integer, null: false
    field :for_boarding, Boolean, null: true
    field :for_alighting, Boolean, null: true

    field :stop_area, Types::StopAreaType, null: false, description: "The StopPoint's StopArea"
    def stop_area
      LazyLoading::StopRelation.new(context, object.stop_area_id)
    end
  end
end
