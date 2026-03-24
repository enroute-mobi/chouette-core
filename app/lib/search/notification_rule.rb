# frozen_string_literal: true

module Search
  class NotificationRule < Base
    extend Enumerize

    # All search attributes
    attribute :email
    attribute :notification_type
    attribute :rule_type
    attribute :operation_statuses
    attribute :start_date, type: Date
    attribute :end_date, type: Date
    attribute :lines

    period :period, :start_date, :end_date

    enumerize :notification_type, in: ::NotificationRule.notification_type.values
    enumerize :rule_type, in: ::NotificationRule.rule_type.values, multiple: true
    enumerize :operation_statuses, in: ::NotificationRule.operation_statuses.values, multiple: true

    attr_accessor :workbench

    alias_method :line_ids, :lines

    def searched_class
      ::NotificationRule
    end

    def query(scope)
      Query::NotificationRule.new(scope)
        .email(email)
        .in_period(period)
        .notification_type(notification_type)
        .rule_type(rule_type)
        .operation_statuses(operation_statuses)
        .lines(lines)
    end

    def line_items
      Rabl::Renderer.new('autocomplete/lines', Chouette::Line.where(id: lines), format: :hash, view_path: 'app/views').render
    end

    def candidate_operation_statuses
      ::NotificationRule.operation_statuses.values
    end

    def candidate_lines
      workbench.lines
    end

    class Order < ::Search::Order
      attribute :created_at, default: :desc
      attribute :notification_type
      attribute :priority
    end
  end
end
