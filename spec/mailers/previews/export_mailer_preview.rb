# Preview all emails at http://localhost:3000/rails/mailers/calendar_mailer
class ExportMailerPreview < ActionMailer::Preview

  def finished
    ExportMailer.finished(Export::Base.first.id, User.first.email)
  end

end