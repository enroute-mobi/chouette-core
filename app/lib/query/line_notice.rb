module Query
  class LineNotice < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        title = table[:title].matches("%#{value}%")
        content = table[:content].matches("%#{value}%")

        scope.where(title.or(content))
      end
    end

    def line(value)
      change_scope(if: value.present?) do |scope|
        scope.with_lines([value])
      end
    end
  end
end
