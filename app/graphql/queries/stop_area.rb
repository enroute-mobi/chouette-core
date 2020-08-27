module Queries
  class StopArea < Queries::BaseQuery
    description 'Find a stop area'

    argument :objectid, String, required: false
    argument :registration_number, String, required: false

    type Types::StopAreaType, null: true

    def resolve(objectid: nil, registration_number: nil)
      context[:target_referential].stop_areas.find_by({objectid: objectid, registration_number: registration_number}.compact)
    end
  end
end
