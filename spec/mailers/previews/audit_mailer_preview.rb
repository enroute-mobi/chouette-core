# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class AuditMailerPreview < ActionMailer::Preview

  def audit
    AuditMailer.audit()
  end

end