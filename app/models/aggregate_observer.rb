class AggregateObserver < ActiveRecord::Observer

  def after_update(aggregate)
    return unless email_sendable_for?(aggregate)
    aggregate = aggregate
    user = User.find_by_name(aggregate.creator)
    MailerJob.perform_later("AggregateMailer", "finished", [aggregate.id, user.id])
  end

  private

  def email_sendable_for?(aggregate)
    Aggregate.finished_statuses.include?(aggregate.status)
  end
end
