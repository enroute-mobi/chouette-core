module Queries
  class Lines < Queries::BaseQuery
    description 'Find all lines'

    type Types::LineType.connection_type, null: false

    def resolve
      context[:target_referential].lines
    end
  end
end