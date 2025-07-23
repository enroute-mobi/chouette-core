module Query
  class Operation < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where name.matches("%#{value}%")
      end
    end

    def user_statuses(user_statuses)
      change_scope(if: value_present?(user_statuses)) do |scope|
        scope.where(user_status: user_statuses)
      end
    end

    def statuses(*statuses)
      statuses = statuses.flatten

      change_scope(if: value_present?(statuses)) do |scope|
        scope.where(status: statuses)
      end
    end

    def workbenches(*workbenches)
      workbenches = workbenches.flatten
      change_scope(if: workbenches.present?) do |scope|
        scope.where workbench: workbenches
      end
    end

    def in_period(period)
      change_scope(if: period.present?) do |scope|
        scope.where started_at: period.infinite_time_range
      end
    end
  end
end
