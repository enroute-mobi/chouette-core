module NotifiableSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :notification_target, in: %w[none user workbench], default: :user
    belongs_to :user
  end

  class_methods do
    def notification_target_options
      notification_target.values.map { |k| [k && "enumerize.notification_target.#{k}".t, k] }
    end
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

  def notification_users
    case notification_target.to_s
      when 'none', '' then []
      when 'user' then [user]
      when 'workbench' then workbench_for_notifications.users
      when 'workgroup' then workgroup_for_notifications.workbenches.map(&:users)
    end.compact.flatten
  end

  def has_notification_recipients?
    notification_target.present? && notification_target.to_s != 'none'
  end
end
