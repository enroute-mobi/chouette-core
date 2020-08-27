module Queries
  class Line < Queries::BaseQuery
    description 'Find a line'

    argument :objectid, String, required: false
    argument :registration_number, String, required: false

    type Types::LineType, null: true

    def resolve(objectid: nil, registration_number: nil)
      context[:target_referential].lines.find_by({objectid: objectid, registration_number: registration_number}.compact)
    end
  end
end
