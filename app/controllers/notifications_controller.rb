class NotificationsController < ChouetteController
  def index
    # See CHOUETTE-2407
    render json: {}
  end
end
