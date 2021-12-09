class SentinelMailer < ApplicationMailer
  def notify_incoming_holes(recipients, referential)
    @referential = referential
    mail bcc: recipients, subject: t('mailers.sentinel_mailer.finished.subject')
  end
end
