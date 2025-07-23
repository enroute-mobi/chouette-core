module Query
  class WorkgroupAggregate < Query::LegacyOperation
    def text(value)
      change_scope(if: value.present?) do |scope|
        creator = scope.arel_table[:creator]
        scope.where creator.matches("%#{value}%")
      end
    end
  end
end
