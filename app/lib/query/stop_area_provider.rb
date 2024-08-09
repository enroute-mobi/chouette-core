module Query
  class StopAreaProvider < Query::Operation
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")

        scope.where(name.or(objectid))
      end
    end
  end
end