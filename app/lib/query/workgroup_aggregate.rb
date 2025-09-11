module Query
  class WorkgroupAggregate < Query::Operation
    def text(value)
      change_scope(if: value.present?) do |scope|
        creator = scope.arel_table[:creator]
        scope.where creator.matches("%#{value}%")
      end
    end
  end
end
