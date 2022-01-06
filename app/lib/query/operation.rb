module Query
  class Operation < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where name.matches("%#{value}%")
      end
    end

    def user_statuses(user_statuses)
      unless user_statuses.blank?
        statuses ::Operation::UserStatus.find(user_statuses).flat_map(&:operation_statuses)
      end

      self
    end

    def statuses(*statuses)
      statuses = statuses.flatten

      change_scope(if: statuses.present?) do |scope|
        scope.having_status statuses
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
