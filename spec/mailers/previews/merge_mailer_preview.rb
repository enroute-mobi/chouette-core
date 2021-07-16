# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class MergeMailerPreview < ActionMailer::Preview

  def finished
    MergeMailer.finished(Merge.first.id, User.first.email)
  end

end