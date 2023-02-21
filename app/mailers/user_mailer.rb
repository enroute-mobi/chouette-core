class UserMailer < ApplicationMailer
  add_template_helper MailerHelper

  def invitation_from_user user, from_user
    @from_user = from_user
    @user = user
    @token = user.instance_variable_get "@raw_invitation_token"
    mail to: user.email, subject: mail_subject('mailers.user_mailer.invitation_from_user.subject', {app_name: 'brandname'.t, translate: true})
  end
end
