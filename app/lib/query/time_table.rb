# frozen_string_literal: true

module Query
  class TimeTable < Base
    def comment(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        comment = table[:comment].matches("%#{value}%")
        objectid = table[:objectid].matches("%#{value}%")

        scope.where(comment.or(objectid))
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where('daterange(start_date, end_date) && ? OR (start_date IS NULL AND end_date IS NULL)', period.to_postgresql_daterange)
      end
    end
  end
end
