class NotificationRule::Workbench < NotificationRule
	def self.sti_name
    'workbench'
  end

	def self.policy_class
		NotificationRulePolicy
	end

	def recipients
		workbench.users
	end
end
