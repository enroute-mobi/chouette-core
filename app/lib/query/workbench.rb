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

    # def line_status(status)
    #   change_scope(if: status.present?) do |scope|
    #     if status == "deactivated"
    #       scope.where(deactivated: true)
    #     else
    #       scope.where(deactivated: false)
    #     end
    #   end
    # end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where('daterange(created_at, merged_at) && ? OR (created_at IS NULL AND merged_at IS NULL)', period.to_postgresql_daterange)
      end
    end

    # TODO Could use a nice RecurviseQuery common object
    # delegate :table_name, to: Workbench
    # private :table_name

    # private

  end
end
