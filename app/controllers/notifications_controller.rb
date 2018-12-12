class NotificationsController < ChouetteController
  def index
    render json: {} && return unless params[:channel]

    notifications = Notification.where(channel: params[:channel]).order(:created_at)
    if params[:lastSeen] && params[:lastSeen].to_i > 0
      notifications = notifications.where('id > ?', params[:lastSeen])
    else
      notifications = notifications.last(1)
    end
    render json: notifications.map(&:full_payload)
  end
end
