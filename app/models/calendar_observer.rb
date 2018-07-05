class CalendarObserver < ActiveRecord::Observer
  def after_update(calendar)
    return unless email_sendable_for?(calendar)

    User.from_workgroup(calendar.workgroup_id).each do |user|
      MailerJob.perform_later("CalendarMailer", "updated", [calendar.id, user.id])
    end
  end

  def after_create(calendar)
    return unless email_sendable_for?(calendar)

    User.from_workgroup(calendar.workgroup_id).each do |user|
      MailerJob.perform_later("CalendarMailer", "created", [calendar.id, user.id])
    end
  end

  private

  def enabled?
    return true unless Rails.configuration.respond_to?(:enable_calendar_observer)
    !!Rails.configuration.enable_calendar_observer
  end

  def email_sendable_for?(calendar)
    enabled? && calendar.shared
  end
end
