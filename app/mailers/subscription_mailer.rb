class SubscriptionMailer < ApplicationMailer
  add_template_helper MailerHelper

  def self.recipients
    Chouette::Config.subscription.notification_recipients
  end

  def self.enabled?
    recipients.present?
  end

  def self.new_subscription(user)
    created(user.id).deliver_later if enabled?
  end

  def created user_id
    @user = User.find(user_id)
    mail to: self.class.recipients, subject: mail_subject('created')
  end
end
