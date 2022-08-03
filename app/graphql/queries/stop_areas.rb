module Queries
  class StopAreas < Queries::BaseQuery
    description 'Find all stop areas'

    type Types::StopAreaType.connection_type, null: false

    def resolve
      context[:target_referential].stop_areas
    end
  end
end
