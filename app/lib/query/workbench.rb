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
        query = []

        query << '(failed_at IS NOT NULL)' if states.include?('failed')
        query << '(archived_at IS NOT NULL)' if states.include?('archived')
        query << '(ready = false AND failed_at IS NULL)' if states.include?('pending')
        query << '(ready = true)' if states.include?('active')

        scope.where(query.join(' OR '))
      end
    end

    def workbench_id(value)
      where(value, :eq, :workbench_id)
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        # scope.joins(:metadatas).where("referential_metadata.periodes && daterange(?) ", period.to_postgresql_daterange)
        scope.joins(:metadatas).where("referential_metadata.periodes[1] && ?", period.to_postgresql_daterange)
      end
    end
  end
end
