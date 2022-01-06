class MergeMailer < ApplicationMailer
  def finished(merge_id, recipient, status = nil)
    @merge = Merge.find(merge_id)
    @status = status || @merge.status
    mail to: recipient, subject: t('mailers.merge_mailer.finished.subject')
  end
end
