class NotifiableOperationObserver < ActiveRecord::Observer
  observe Export::Gtfs, Export::Netex, Export::NetexGeneric, Import::Workbench, Aggregate, Merge

  def after_update(operation)
    return unless email_sendable_for?(operation)

    workbench = operation.try(:workbench) || operation.try(:workbench_for_notifications)
    return unless workbench

    workbench.notification_center.notify(operation)
  rescue StandardError => e
    Chouette::Safe.capture "Notification processing failed for #{operation.class}##{operation.id}", e
  end

  private

  def email_sendable_for?(operation)
    return false if operation.try(:notified_recipients_at)

    operation.class.finished_statuses.include?(operation.status)
  end
end
