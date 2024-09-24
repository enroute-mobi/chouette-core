module Query
  class Route < Base

    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")

        scope.where(name.or(objectid))
      end
    end

    def wayback(value)
      where(value, :in, :wayback)
    end

    def without_opposite_route
      scope.where(opposite_route: nil)
    end
  end
end