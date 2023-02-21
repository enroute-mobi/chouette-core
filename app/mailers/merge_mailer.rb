class MergeMailer < ApplicationMailer
  def finished(merge_id, recipient, status = nil)
    @merge = Merge.find(merge_id)
    @status = status || @merge.status
    mail to: recipient, subject: mail_subject('mailers.merge_mailer.finished.subject')
  end
end
