module RealtimeNotifiableSupport
  extend ActiveSupport::Concern

  def workbench_for_notifications
    workbench || referential.workbench || referential.workgroup&.owner_workbench
  end

  def url_for_notifications(use_self=false)
    object = self
    object = parent if self.try(:parent) && !use_self
    [workbench_for_notifications, object]
  end

  def urls_to_refresh
    ([self] + children).map{ |i| polymorphic_url(i.url_for_notifications(true), only_path: true) }
  end

  def automated_operation?
    try(:publication).present?
  end

  def notify_state
    return if automated_operation?

    payload = self.slice(:id, :status, :name, :parent_id)
    payload.update({
      status_html: operation_status(self.status).html_safe,
      message_key: "#{self.class.name.underscore.gsub('/', '.')}.#{self.status}",
      url: polymorphic_url(url_for_notifications, only_path: true),
      urls_to_refresh: urls_to_refresh,
      unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}"
    })
    if self.class < Import::Base
      payload[:fragment] = "import-fragment"
    end
    if self.class < Export::Base
      payload[:fragment] = "export-fragment"
    end
    Notification.create! channel: workbench_for_notifications.notifications_channel, payload: payload
  end

  def notify_child_progress child, progress
    return progress unless self.children.present?

    index = self.children.index child
    notify_progress (index+progress)/self.children.count
  end

  def notify_progress progress
    @previous_progress ||= 0
    return unless progress - @previous_progress >= 0.01
    @previous_progress = progress
    if parent
      parent.notify_child_progress self, progress
    else
      payload = self.slice(:id, :status, :name, :parent_id)
      payload.update({
        message_key: "#{self.class.name.underscore.gsub('/', '.')}.progress",
        status_html: operation_status(self.status).html_safe,
        url: polymorphic_url(url_for_notifications, only_path: true),
        urls_to_refresh: urls_to_refresh,
        unique_identifier: "#{self.class.name.underscore.gsub('/', '.')}-#{self.id}",
        progress: (progress*100).to_i
      })
      if self.class < Import::Base
        payload[:fragment] = "import-fragment"
      end
      Notification.create! channel: workbench_for_notifications.notifications_channel, payload: payload
    end
  end

  def operation_progress_weight(operation_name)
    1
  end

  def operations_progress_total_weight
    steps_count
  end

  def operation_relative_progress_weight(operation_name)
    operation_progress_weight(operation_name).to_f/operations_progress_total_weight
  end

  def notify_operation_progress(operation_name)
    @progress ||= 0
    @progress += operation_relative_progress_weight(operation_name)
    notify_progress @progress
  end

  def notify_sub_operation_progress(operation_name, progress)
    notify_progress(@progress + operation_relative_progress_weight(operation_name)*progress) if @progress
  end
end
