module Types
  class QueryType < Types::BaseObject
    field :lines, resolver: Queries::Lines
    field :line, resolver: Queries::Line
  end
end
