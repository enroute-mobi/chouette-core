class NotifiableOperationObserver < ActiveRecord::Observer
  observe Export::Gtfs, Export::Netex, Export::NetexGeneric, Import::Workbench, Aggregate, NightlyAggregate, Merge, ComplianceCheckSet

  def after_update(operation)
    begin
      return unless email_sendable_for?(operation)

      workbench = operation.try(:workbench) || operation.try(:workbench_for_notifications)
      return unless workbench

      workbench.notification_center.notify(operation)
    rescue => e
      Chouette::Safe.capture "Notification processing failed for #{operation.class}##{operation.id}", e
    end
  end

  private

  def email_sendable_for?(operation)
    return false if operation.is_a?(ComplianceCheckSet) && operation.context != 'manual'
    return false if operation.try(:notified_recipients_at)

    operation.class.finished_statuses.include?(operation.status)
  end
end
