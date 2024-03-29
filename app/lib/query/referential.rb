module Query
  class Referential < Base
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
        scope.include_metadatas_lines([value])
      end
    end

    def statuses(statuses)
      change_scope(if: statuses.present?) do |scope|
        query = []

        query << '(ready = false AND failed_at IS NOT NULL)' if statuses.include?('failed')
        query << '(archived_at IS NOT NULL AND failed_at IS NULL)' if statuses.include?('archived')
        query << '(ready = false AND failed_at IS NULL AND archived_at IS NULL)' if statuses.include?('pending')
        query << '(ready = true AND failed_at IS NULL AND archived_at IS NULL)' if statuses.include?('active')

        scope.where(query.join(' OR '))
      end
    end

    def workbenches(workbenches)
      change_scope(if: workbenches.present?) do |scope|
        scope.where(workbench_id: workbenches)
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.joins(:metadatas).where('? && ANY(referential_metadata.periodes)', period.to_postgresql_daterange)
      end
    end
  end
end
