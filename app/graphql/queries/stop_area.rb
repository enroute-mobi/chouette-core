module Queries
  class StopArea < Queries::BaseQuery
    description 'Find a stop area'

    argument :objectid, String, required: false

    type Types::StopAreaType, null: true

    def resolve(objectid: nil)
      context[:target_referential].stop_areas.find_by({objectid: objectid}.compact)
    end
  end
end