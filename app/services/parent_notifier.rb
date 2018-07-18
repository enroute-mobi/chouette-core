class ParentNotifier
  def initialize(klass)
    @klass = klass
  end

  def notify_when_finished(collection = nil)
    collection ||= objects_pending_notification
    collection.each(&:notify_parent)
  end

  def objects_pending_notification
    if @klass.respond_to?(:objects_pending_notification)
      @klass.objects_pending_notification
    else
      @klass
        .where(
          notified_parent_at: nil,
          status: @klass.finished_statuses
        )
        .where.not(parent: nil)
    end
  end
end
