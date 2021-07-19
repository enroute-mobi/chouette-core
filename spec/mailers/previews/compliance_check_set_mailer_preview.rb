# Preview all emails at http://localhost:3000/rails/mailers/compliance_check_set_mailer
class ComplianceCheckSetMailerPreview < ActionMailer::Preview

  def finished
    ComplianceCheckSetMailer.finished(ComplianceCheckSet.first.compliance_control_set_id, User.first.name)
  end

end