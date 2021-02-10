class SubscriptionMailer < ApplicationMailer
  add_template_helper MailerHelper

  def self.enabled?
    Rails.configuration.subscriptions_notifications_recipients.present?
  end

  def created user_id
    @user = User.find(user_id)
    mail to: Rails.configuration.subscriptions_notifications_recipients, subject: t('mailers.subscription_mailer.created.subject')
  end
end
