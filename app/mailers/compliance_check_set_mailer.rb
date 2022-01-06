class ComplianceCheckSetMailer < ApplicationMailer

  def finished(ccset_id, recipient, status=nil)
    @ccset = ComplianceCheckSet.find(ccset_id)
    @status = status || @ccset.status
    mail to: recipient, subject: t('mailers.compliance_check_set_mailer.finished.subject')
  end
end
