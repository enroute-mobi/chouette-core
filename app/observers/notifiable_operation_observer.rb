class NotifiableOperationObserver < ActiveRecord::Observer
  def mailer_name(model)
    "#{model.class.name}Mailer"
  end

  def mailer(model)
    mailer_name(model).constantize
  end

  def after_update(model)
    return unless email_sendable_for?(model)

    line_ids = begin
      model.line_ids
    rescue
      []
    end

    NotificationCenter::NotifyUsers.new(model, line_ids).call do |recipients|
      mailer(model).finished(model.id, recipients, model.status).deliver_later

      model.update_column(:notified_recipients_at, Time.now)
    end
  end

  private

  def email_sendable_for?(model)
    model.class.finished_statuses.include?(model.status) && model.notified_recipients_at.blank? && model.has_notification_recipients?
  end
end
