class MergeObserver < ActiveRecord::Observer

  def after_update(merge)
    return unless email_sendable_for?(merge)
    merge = merge
    user = User.find_by_name(merge.creator)
    MailerJob.perform_later("MergeMailer", "finished", [merge.id, user.id])
  end

  private

  def email_sendable_for?(merge)
    Merge.finished_statuses.include?(merge.status)
  end
end
