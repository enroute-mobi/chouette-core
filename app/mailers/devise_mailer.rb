class DeviseMailer < Devise::Mailer
  add_template_helper MailerHelper
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include MailerHelper

  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def mail_subject(method:, attributes: {})
    super i18n: "mailers.#{method}.subject", attributes: attributes
  end

  def confirmation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject(method: 'confirmation_mailer')
  end

  def invitation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject(method: 'invitation_mailer')
  end

  def unlock_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject(method: 'unlock_mailer')
  end

  def reset_password_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject(method: 'password_mailer.updated')
  end
end
