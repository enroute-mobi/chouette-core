class NotificationRule::User < NotificationRule
	validates_length_of :user_ids, minimum: 1

	def self.sti_name
    'user'
  end

	def self.policy_class
		NotificationRulePolicy
	end

	def recipients
		workbench.users.where(id: users_ids)
	end
end
