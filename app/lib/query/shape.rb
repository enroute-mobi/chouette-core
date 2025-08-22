# frozen_string_literal: true

module Query
  class Shape < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        uuid = Arel::Nodes::NamedFunction.new('CAST', [scope.arel_table[:uuid].as('VARCHAR')])
        scope.where(name.matches("%#{value}%")).or(scope.where(uuid.matches("%#{value}%")))
      end
    end
  end
end
