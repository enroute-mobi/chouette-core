class ComplianceCheckSetMailer < ApplicationMailer

  def finished(ccset_id, recipient, status=nil)
    @ccset = ComplianceCheckSet.find(ccset_id)
    @status = status || @ccset.status
    mail to: recipient, subject: mail_subject
  end
end
