module Query
  class NotificationRule < Base
		def email(value)
			return self if value.blank?

			self.scope = scope
				.joins(workbench: :organisation)
				.joins("LEFT JOIN users ON users.organisation_id = organisations.id AND notification_rules.user_ids @> ARRAY[users.id]")
				.where('users.email LIKE :value OR notification_rules.external_email LIKE :value', value: "%#{value.downcase}%")

			self
		end

		def period(daterange)
			return self if value.blank?

			self.scope = scopwwhere('period && daterange(:begin, :end)', begin: daterange.min, end: daterange.max + 1.day) } #Need to add one day because of PostgreSQL behaviour with daterange (exclusvive end)

			self
		end

		def notification_type(value)
			return self if value.blank?

			self.scope = scope.where('ARRAY[?]::text[] @> ARRAY[notification_rules.notification_type]::text[]', value)

			self
		end

		def rule_type(value)
			return self if value.blank?

			self.scope = scope.where('ARRAY[?]::text[] @> ARRAY[notification_rules.rule_type]::text[]', value)

			self
		end

		def operation_statuses(statuses)
			return self if value.blank?

			self.scope = where('array_length(operation_statuses, 1) = 0 OR operation_statuses::text[] && ARRAY[?]', statuses)

			self
		end

		def line_ids(line_ids)
			return self if value.blank?

			self.scope = where('array_length(line_ids, 1) = 0 OR line_ids && ARRAY[?]', line_ids)

			self
		end
  end
end
