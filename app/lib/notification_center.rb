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
    Notification.new(operation, rules: rules.active.for_operation(operation)).deliver
  end

  def recipients(notification_type, line_ids: nil, period: nil, base_recipients: [])
    rules_scope = rules.where(notification_type: notification_type)

    if line_ids.present?
      rules_scope = rules_scope.for_lines(line_ids)
    end

    if period
      rules_scope = rules_scope.covering(period)
    end

    rules_scope.recipients(base_recipients)
  end

  def has_recipients?(notification_type, line_ids: nil, period: nil, base_recipients: [])
    recipients(notification_type, line_ids: line_ids, period: period, base_recipients: base_recipients).present?
  end

  class Notification

    def initialize(operation, rules: NotificationRule.none)
      @operation = operation
      @rules = rules
    end
    attr_reader :operation, :rules

    def recipients
      rules.recipients(operation.notification_recipients)
    end

    def deliver
      return if operation.notified_recipients_at

      Rails.logger.info "Notify #{recipients.inspect} for #{operation.class}##{operation.id} (status: #{operation.status})"

      recipients.each do |recipient|
        mailer.finished(operation.id, recipient, operation.status).deliver_later
      end

      operation.update_column :notified_recipients_at, Time.zone.now
    end

    def mailer
      @mailer ||= mailer_name.constantize
    end

    def mailer_name
      if operation.class.respond_to?(:mailer_name)
        operation.class.mailer_name
      else
        "#{operation.class.name}Mailer"
      end
    end

  end

end
