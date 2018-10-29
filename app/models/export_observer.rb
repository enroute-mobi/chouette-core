class ExportObserver < ActiveRecord::Observer
  observe Export::Gtfs, Export::Netex

  def after_update(export)
    return unless email_sendable_for?(export)
    user = User.find_by_name(export.creator)
    MailerJob.perform_later("ExportMailer", "finished", [export.id, user.id])
  end

  private

  def email_sendable_for?(export)
    export.finished?
  end
end
