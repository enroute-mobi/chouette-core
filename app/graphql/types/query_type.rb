module Types
  class QueryType < Types::BaseObject
    field :lines, resolver: Queries::Lines, max_page_size: 500
    field :line, resolver: Queries::Line
    field :stop_areas, resolver: Queries::StopAreas, max_page_size: 500
    field :stop_area, resolver: Queries::StopArea
  end
end
