module Search
  class NotificationRule < Base
		extend Enumerize
	
    # All search attributes
    attribute :email
    attribute :notification_type
    attribute :rule_type
    attribute :operation_statuses
    attribute :period
    attribute :line_ids

		enumerize :notification_type, in: ::NotificationRule.notification_type.values
		enumerize :rule_type, in: ::NotificationRule.rule_type.values, multiple: true
		enumerize :operation_statuses, in: ::NotificationRule.operation_statuses.values, multiple: true

    def query
			Query::NotificationRule.new(scope)
				.email(email)
				.period(period)
				.notification_type(notification_type)
				.rule_type(rule_type)
				.operation_statuses(operation_statuses)
				.line_ids(line_ids)
    end

		def line_items
			Rabl::Renderer.new('autocomplete/lines', Chouette::Line.where(id: line_ids), format: :hash, view_path: 'app/views').render
		end

		def period
			ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Range
				.new(ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Date.new)
				.cast_value(super.presence)
		end

		class Order < ::Search::Order
      attribute :created_at, default: :desc
			attribute :notification_type
			attribute :priority
    end

		private
	end
end


