module Query
  class LineGroup < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where(name.matches("%#{value}%"))
      end
    end

    def lines(value)
      change_scope(if: value.present?) do |scope|
        scope.where(lines: value)
      end
    end

    def line_provider_id(value)
      where(value, :eq, :line_provider_id)
    end
  end
end
