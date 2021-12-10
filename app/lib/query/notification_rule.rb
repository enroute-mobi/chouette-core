module Query
  class NotificationRule < Base
		def email(value)
			set_scope(value) do
				scope
					.joins(workbench: :organisation)
					.left_joins(organisation: :users)
					.where(
						%{
							CASE
								WHEN notification_rules.target_type = 'external_email' THEN notification_rules.external_email LIKE :value
								WHEN notification_rules.target_type = 'user' THEN notification_rules.user_ids @> ARRAY[users.id] AND users.email LIKE :value
								WHEN notification_rules.target_type = 'workbench' THEN users.email LIKE :value
							END
						},
						value: "%#{value.downcase}%"
					)
					.distinct
			end
		end

		def period(value)
			set_scope(value) do
				scope.where('period::daterange && daterange(:begin, :end)', begin: value.min, end: value.max + 1.day) #Need to add one day because of PostgreSQL behaviour with daterange (exclusvive end)
			end
		end

		def notification_type(value)
			set_scope(value) do
				scope.where('ARRAY[?]::text[] @> ARRAY[notification_rules.notification_type]::text[]', value)
			end
		end

		def rule_type(value)
			set_scope(value) do
				scope.where('ARRAY[?]::text[] @> ARRAY[notification_rules.rule_type]::text[]', value)
			end
		end

		def operation_statuses(value)
			set_scope(value) do
				scope.where(operation_statuses: []).or(scope.where('operation_statuses::text[] && ARRAY[?]', value))
			end
		end

		def line_ids(value)
			set_scope(value) do
				scope.where(line_ids: []).or(scope.where('line_ids::integer[] && ARRAY[?]', value))
			end
		end
  end
end
