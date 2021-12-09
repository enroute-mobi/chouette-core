module NotificationCenter
	class NotifyUsers

		attr_reader :operation, :workbench, :line_ids

		def initialize(operation, line_ids)
			@operation = operation
			@workbench = operation.workbench_for_notifications
			@line_ids = line_ids
		end

		def notification_rules
			@notification_rules ||= workbench
				.notification_rules
				.active
				.for_operation(operation, line_ids)
				.order(priority: :asc)
		end

		def recipients
			@recipients ||= notification_rules.reduce(operation.notification_users) do |list, nr|
				case nr.rule_type
				when 'notify' then list | nr.recipients
				when 'block' then list - nr.recipients
				else
					list
				end
			end.uniq(&:email).map(&:email_recipient)
		end

		def call
			begin
				yield recipients
			rescue => e
				Chouette::Safe.capture "Can't notify users", e
			end
		end
	end
end
