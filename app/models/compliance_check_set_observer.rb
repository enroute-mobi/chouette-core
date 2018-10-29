class ComplianceCheckSetObserver < ActiveRecord::Observer

  def after_update(ccset)
    return unless email_sendable_for?(ccset)
    ccset = ccset
    MailerJob.perform_later("ComplianceCheckSetMailer", "finished", [ccset.id, ccset.metadata.creator_id])
  end

  private

  def email_sendable_for?(ccset)
    ComplianceCheckSet.finished_statuses.include?(ccset.status)
  end
end
