module Queries
  class StopArea < Queries::BaseQuery
    description 'Find a stop area'

    argument :id, Integer, required: false
    argument :objectid, String, required: false

    type Types::StopAreaType, null: true

    def resolve(id: nil, objectid: nil)
      context[:target_referential].stop_areas.find_by({id: id, objectid: objectid}.compact)
    end
  end
end