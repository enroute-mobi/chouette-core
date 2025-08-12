# frozen_string_literal: true

module Query
  class RoutingConstraintZone < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")

        scope.where(name.or(objectid))
      end
    end

    def route_id(value)
      where(value, :eq, :route_id)
    end
  end
end
