# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class ComplianceCheckSetMailerPreview < ActionMailer::Preview

  def finished
    ComplianceCheckSet.finished(ComplianceCheckSet.first.compliance_control_set_id, User.first.name)
  end

end