class AggregateMailer < ApplicationMailer
  def finished(aggregate_id, recipient, status = nil)
    @aggregate = Aggregate.find(aggregate_id)
    @status = status || @aggregate.status
    mail to: recipient, subject: mail_subject
  end
end
