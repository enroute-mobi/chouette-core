class AuditMailer < ApplicationMailer
  def enabled?
    !!Rails.configuration.enable_automated_audits
  end

  def audit content
    return unless enabled?
    @content = content
    mail to: Rails.configuration.automated_audits_recipients, subject: t('mailers.audit_mailer.audit.subject', date: Time.now.l, host: URI.parse(Rails.application.config.action_mailer.asset_host).host)
  end
end
