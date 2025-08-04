# frozen_string_literal: true

module Query
  class Calendar < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        scope.where(table[:name].matches("%#{value}%"))
      end
    end

    def shared(value)
      change_scope(if: !value.nil?) do |scope|
        scope.where(shared: value)
      end
    end

    def contains_date(value)
      change_scope(if: value.present?) do |scope|
        scope.contains_date(value)
      end
    end
  end
end
