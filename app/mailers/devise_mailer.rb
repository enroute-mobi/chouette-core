class DeviseMailer < Devise::Mailer
  add_template_helper MailerHelper
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def subject_prefix
    Chouette::Config.mailer.subject_prefix
  end

  def mail_subject(subject = "finished", options = {})
    subject_translated = t("mailers.#{subject}.subject", options)
    [subject_prefix, subject_translated].compact.join(' ')
  end
  
  def confirmation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('confirmation_mailer')
  end

  def invitation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('invitation_mailer')
  end

  def unlock_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('unlock_mailer')
  end

  def reset_password_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('password_mailer.updated')
  end
end
