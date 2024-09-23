# frozen_string_literal: true

module Query
  class Network < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        objectid = scope.arel_table[:objectid]
        scope.where(name.matches("%#{value}%")).or( scope.where(objectid.matches("%#{value}%")))
      end
    end
  end
end
