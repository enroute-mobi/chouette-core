# Preview all emails at http://localhost:3000/rails/mailers/audit_mailer
class AuditMailerPreview < ActionMailer::Preview

  def audit
    AuditMailer.audit('')
    # AuditMailer.audit(job.payload_object.mail_content).deliver_now
  end

end