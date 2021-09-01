module Query
  class Import < Base
    def text(value)
      unless value.blank?
        self.scope = scope.where 'imports.name ILIKE ?', "%#{value}%"
      end

      self
    end

    def statuses(statuses)
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

    def include_in_date_range(date_range)
      if date_range.present?
        self.scope = scope.where started_at: date_range
      end

      self
    end
  end
end
