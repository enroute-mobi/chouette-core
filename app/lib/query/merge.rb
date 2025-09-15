module Query
  class Merge < Query::Operation
    def text(value)
      change_scope(if: value.present?) do |scope|
        creator = scope.arel_table[:creator]
        name = scope.arel_table[:name]

        scope.where creator.matches("%#{value}%").or(name.matches("%#{value}%"))
      end
    end
  end
end