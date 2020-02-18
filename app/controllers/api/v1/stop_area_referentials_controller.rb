class Api::V1::StopAreaReferentialsController < ActionController::Base
  respond_to :json, :xml
  wrap_parameters :stop_area_referential, include: WebhookEvent::StopAreaReferential.permitted_attributes

  layout false
  before_action :authenticate

  def webhook
    if event.valid?
      render json: {}, status: :ok
    else
      render json: { message: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  protected

  def event
    @event ||= WebhookEvent::StopAreaReferential.new event_params
  end

  def current_stop_area_referential
    @current_stop_area_referential ||= current_workgroup.stop_area_referential.tap do |stop_area_referential|
      raise ActiveRecord::RecordNotFound unless stop_area_referential.id == params[:id]
    end
  end

  def current_workgroup
    @current_workgroup
  end

  private

  def event_params
    params.require(:stop_area_referential).permit(*permitted_attributes)
  end

  # Accepts
  # * normal attributes
  # * hash attributes for single resources
  # * array of hash with id parameter for several resources
  #
  # [ "type", "stop_place", "stop_places", "quay", "quays",
  #   {"stop_place"=>{}, "stop_places"=>[:id], "quay"=>{}, "quays"=>[:id]}]
  def permitted_attributes
    @permitted_attributes ||= [
      "type",
      *WebhookEvent::StopAreaReferential.resource_names,
      Hash[WebhookEvent::StopAreaReferential.resource_names.map { |name| [name, name.end_with?('s') ? [:id] : {} ] }]
    ]
  end

  def authenticate
    authenticate_or_request_with_http_token do |token|
      api_key = ApiKey.find_by token: token
      @current_workgroup = api_key.workgroup

      @current_workgroup.present?
    end
  end
end
