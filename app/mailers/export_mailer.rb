class ExportMailer < ApplicationMailer

  def finished(export_id, recipient, status = nil)
    @export = Export::Base.find(export_id)
    @status = status || @export.status
    mail to: recipient, subject: mail_subject
  end
end
