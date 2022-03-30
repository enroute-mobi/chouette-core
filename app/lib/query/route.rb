module Query
  class Route < Base
    def without_opposite_route
      scope.where(opposite_route: nil)
    end
  end
end