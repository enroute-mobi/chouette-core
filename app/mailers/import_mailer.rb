class ImportMailer < ApplicationMailer

  def finished(import_id, recipient, import_status = nil)
    @import = Import::Base.find(import_id)
    @import_status = import_status || @import.status
    mail to: recipient, subject: mail_subject
  end
end
