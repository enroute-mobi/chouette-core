class ImportMailer < ApplicationMailer

  def finished(import_id, recipient, status = nil)
    @import = Import::Base.find(import_id)
    @status = status || @import.status
    mail to: recipient, subject: mail_subject
  end
end
