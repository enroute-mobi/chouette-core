module Types
  class QueryType < Types::BaseObject
    field :lines, resolver: Queries::Lines
    field :line, resolver: Queries::Line
    field :stop_areas, resolver: Queries::StopAreas
    field :stop_area, resolver: Queries::StopArea
  end
end
