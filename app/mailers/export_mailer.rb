class ExportMailer < ApplicationMailer

  def finished(export_id, recipient, export_status = nil)
    @export = Export::Base.find(export_id)
    @export_status = export_status || @export.status
    mail to: recipient, subject: mail_subject
  end
end
