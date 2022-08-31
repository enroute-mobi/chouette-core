# frozen_string_literal: true

class SourceRetrievalMailer < ApplicationMailer
  def finished(operation_id, recipient, _status = nil)
    @operation = Source::Retrieval.find(operation_id)
    mail to: recipient, subject: t('mailers.source_retrieval_mailer.finished.subject')
  end
end
