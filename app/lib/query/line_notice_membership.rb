module Query
  class LineNoticeMembership < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        line_notice_table = scope.reflections['line_notice'].klass.arel_table

        title = line_notice_table[:title].matches("%#{value}%")
        content = line_notice_table[:content].matches("%#{value}%")

        scope.joins(:line_notice).where(title.or(content))
      end
    end
  end
end
