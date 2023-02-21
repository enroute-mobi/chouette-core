class SentinelMailer < ApplicationMailer
  def notify_incoming_holes(recipient, referential)
    @referential = referential
    mail to: recipient, subject: mail_subject('mailers.sentinel_mailer.finished.subject')
  end
end
