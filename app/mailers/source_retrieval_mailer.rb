# frozen_string_literal: true

class SourceRetrievalMailer < ApplicationMailer
  def finished(operation_id, recipient, status = nil)
    @operation = Source::Retrieval.find(operation_id)
    @status = status || @operation.user_status
    mail to: recipient, subject: mail_subject
  end
end
