module Queries
  class Line < Queries::BaseQuery
    description 'Find a line'

    argument :id, Integer, required: false
    argument :objectid, String, required: false

    type Types::LineType, null: true

    def resolve(id: nil, objectid: nil)
      context[:target_referential].lines.find_by({id: id, objectid: objectid}.compact)
    end
  end
end