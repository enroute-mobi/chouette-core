class NotificationRule::ExternalEmail < NotificationRule
	validates_presence_of :external_email

	def self.sti_name
    'external_email'
  end

	def self.policy_class
		NotificationRulePolicy
	end

	def recipients
		[::User.new(email: external_email)]
	end
end
