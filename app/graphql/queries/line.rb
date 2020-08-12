module Queries
  class Line < Queries::BaseQuery
    description 'Find a line'

    argument :objectid, String, required: false

    type Types::LineType, null: true

    def resolve(objectid: nil)
      context[:target_referential].lines.find_by({objectid: objectid}.compact)
    end
  end
end