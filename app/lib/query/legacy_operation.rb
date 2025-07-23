module Query
  class LegacyOperation < Query::Operation
    def user_statuses(user_statuses)
      unless user_statuses.blank?
        statuses ::Operation::UserStatus.find(user_statuses).flat_map(&:operation_statuses)
      end

      self
    end
  end
end