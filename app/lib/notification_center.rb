# frozen_string_literal: true

# Manage email notifications send when operations are done
class NotificationCenter
  def initialize(workbench)
    @workbench = workbench
  end
  attr_reader :workbench

  def rules
    @rules ||= workbench.notification_rules.order(priority: :asc)
  end

  def notify(operation)
    Rails.logger.debug "Start notification processing for #{operation.class}##{operation.id}"
    Notification.for(operation).new(operation, rules: rules.active.for_operation(operation)).deliver
  end

  def recipients(notification_type, line_ids: nil, period: nil, base_recipients: [])
    rules_scope = rules.where(notification_type: notification_type)

    rules_scope = rules_scope.for_lines(line_ids) if line_ids.present?

    rules_scope = rules_scope.covering(period) if period

    rules_scope.recipients(base_recipients)
  end

  def has_recipients?(notification_type, line_ids: nil, period: nil, base_recipients: [])
    recipients(notification_type, line_ids: line_ids, period: period, base_recipients: base_recipients).present?
  end

  # Manage notification for a given Operation
  class Notification
    def self.for(operation)
      [LegacyWithTimestampNotification, LegacyNotification, Notification].find { |klass| klass.support?(operation) }
    end

    def self.support?(operation)
      operation.is_a?(Operation)
    end

    def initialize(operation, rules: NotificationRule.none)
      @operation = operation
      @rules = rules
    end
    attr_reader :operation, :rules

    def operation_recipients
      operation.try(:notification_recipients) || []
    end

    def recipients
      @recipients ||= rules.recipients(operation_recipients)
    end

    def current_status
      operation.user_status
    end

    def deliver
      log
      recipients.each do |recipient|
        mailer.finished(operation.id, recipient, current_status).deliver_later
      end
    end

    def log
      logger.info "Notify #{recipients.inspect} for #{operation.class}##{operation.id} (status: #{current_status})"
    end

    def logger
      Rails.logger
    end

    def mailer
      @mailer ||= mailer_name.constantize
    end

    def mailer_name
      if operation.class.respond_to?(:mailer_name)
        operation.class.mailer_name
      else
        "#{operation.class.name.gsub('::', '')}Mailer"
      end
    end
  end

  # Manage notification for a given legacy Operation (not Operation subclasses)
  class LegacyNotification < Notification
    def self.support?(operation)
      !operation.is_a?(Operation)
    end

    def current_status
      operation.status
    end
  end

  # Manage notification for a given legacy Operation with notified_recipients_at
  class LegacyWithTimestampNotification < LegacyNotification
    def self.support?(operation)
      return false unless super(operation)

      operation.respond_to? :notified_recipients_at
    end

    def deliver
      return if operation.notified_recipients_at

      super
      operation.update_column :notified_recipients_at, Time.zone.now
    end
  end
end