# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class UserMailerPreview < ActionMailer::Preview

  def invitation_from_user
    UserMailer.invitation_from_user(User.second, User.first)
  end

end