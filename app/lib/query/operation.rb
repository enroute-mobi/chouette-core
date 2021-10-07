module Query
  class Operation < Base
    def text(value)
      unless value.blank?
        name = scope.arel_table[:name]
        self.scope = scope.where name.matches("%#{value}%")
      end

      self
    end

    def user_statuses(user_statuses)
      unless user_statuses.blank?
        statuses ::Operation::UserStatus.find(user_statuses).flat_map(&:operation_statuses)
      end

      self
    end

    def statuses(*statuses)
      statuses = statuses.flatten
      unless statuses.blank?
        self.scope = scope.having_status statuses
      end

      self
    end

    def workbenches(*workbenches)
      workbenches = workbenches.flatten
      unless workbenches.blank?
        self.scope = scope.where workbench: workbenches
      end

      self
    end

    def in_period(period)
      if period.present?
        self.scope = scope.where started_at: period.infinite_time_range
      end

      self
    end
  end
end
