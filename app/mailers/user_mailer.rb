class UserMailer < ApplicationMailer
  add_template_helper MailerHelper

  def invitation_from_user user, from_user
    @from_user = from_user
    @user = user
    @token = user.instance_variable_get "@raw_invitation_token"
    mail to: user.email, subject: mail_subject(method: 'invitation_from_user', attributes: {app_name: 'brandname'.t})
  end
end
