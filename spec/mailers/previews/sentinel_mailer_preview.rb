# Preview all emails at http://localhost:3000/rails/mailers/sentinel_mailer
class SentinelMailerPreview < ActionMailer::Preview

  def notify_incoming_holes
    SentinelMailer.notify_incoming_holes(Workbench.first, Referential.first)
  end

end
