module Query
  class Workbench < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table

        name = table[:name].matches("%#{value}%")
        objectid_format = table[:objectid_format].matches("%#{value}%")

        scope.where(name.or(objectid_format))
      end
    end

    def line(value)
      change_scope(if: value.present?) do |scope|
        scope.joins(:metadatas).where("? = ANY(referential_metadata.line_ids)", value).distinct
      end
    end

    def states(states)
      change_scope(if: states.present?) do |scope|
        if states.to_s == "failed"
          scope.where.not(failed_at: nil)
        elsif states.to_s == "archived"
          scope.where.not(archived_at: nil)
        elsif states.to_s == "pending"
          scope.where(ready: false)
        else
          scope.where(ready: true)
        end
      end
    end

    def workbench_id(value)
      debugger
      where(value, :eq, :workbench_id)
    end

    # def in_period(period)
    #   change_scope(if: period.present?) do |scope|
    #     scope.joins(:metadatas).where("daterange(begin, end) && ? OR (begin IS NULL AND end IS NULL)", period.to_postgresql_daterange)
    #   end
    # end

    # TODO Could use a nice RecurviseQuery common object
    # delegate :table_name, to: Workbench
    # private :table_name

    # private

  end
end
