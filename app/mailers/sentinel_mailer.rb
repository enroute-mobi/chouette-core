class SentinelMailer < ApplicationMailer
  def notify_incoming_holes(recipient, referential)
    @referential = referential
    mail to: recipient, subject: t('mailers.sentinel_mailer.finished.subject')
  end
end
