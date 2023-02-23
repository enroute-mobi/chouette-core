class DeviseMailer < Devise::Mailer
  add_template_helper MailerHelper
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  include SubjectHelper
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def confirmation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('mailers.confirmation_mailer.subject')
  end

  def invitation_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('mailers.invitation_mailer.subject')
  end

  def unlock_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('mailers.unlock_mailer.subject')
  end

  def reset_password_instructions(user, token, opts={})
    @user  = user
    @token = token
    mail to: @user.email, subject: mail_subject('mailers.password_mailer.updated.subject')
  end
end
