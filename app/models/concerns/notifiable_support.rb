module NotifiableSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :notification_target, in: %w[none user workbench], default: :none
    belongs_to :user
  end

  module ClassMethods
    def notification_target_options
      notification_target.values.map { |k| [k && "operation_support.notification_targets.#{k}".t, k] }
    end
  end

  def notify_relevant_users(mailer, action)
    recipients = notification_recipients
    return unless recipients.present?

    mailer_params = yield(recipients)

    begin
      mailer.constantize.public_send(action, *mailer_params).deliver_later
    rescue => e
      # TODO #8018
      Rails.logger.error "Can't notify users: #{e.message} #{e.backtrace.join("\n")}"
    end

    notify_recipients!
  end

  def notified_recipients?
    notified_recipients_at.present?
  end

  def notify_recipients!
    update_column :notified_recipients_at, Time.now
  end

  def workbench_for_notifications
    workbench
  end

  def workgroup_for_notifications
    workgroup
  end

  def notification_recipients
    return [] unless has_notification_recipients?

    users = if notification_target.to_s == 'user'
      [user]
    elsif notification_target.to_s == 'workbench'
      workbench_for_notifications.users
    else
      workgroup_for_notifications.workbenches.map(&:users)
    end

    users.compact.map(&:email_recipient)
  end

  def has_notification_recipients?
    notification_target.present? && notification_target.to_s != 'none'
  end
end
