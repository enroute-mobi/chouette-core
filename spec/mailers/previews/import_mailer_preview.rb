# Preview all emails at http://localhost:3000/rails/mailers/import_mailer
class ImportMailerPreview < ActionMailer::Preview

  def finished
    ImportMailer.finished(Import::Base.first.id, User.first.email)
  end

end