class Api::V1::LineReferentialsController < Api::V1::WorkbenchController
  respond_to :json, :xml
  wrap_parameters :line_referential, include: [ :type, *WebhookEvent::LineReferential.resource_names ]

  layout false

  def webhook
    if event.valid?
      if event.update_or_create?
        synchronization.source = event.netex_source
        synchronization.update_or_create
      end

      if event.destroyed?
        event.resource_ids.each do |name, resource_ids|
          synchronization.delete name, resource_ids
        end
      end

      logger.info "Synchronization done: #{synchronization.counts}"
      render json: synchronization.counts, status: :ok
    else
      render json: { message: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  protected

  def event
    @event ||= WebhookEvent::LineReferential.new event_params
  end

  def synchronization
    @synchronization ||= Chouette::Sync::Referential.new(line_referential).tap do |sync|
      sync.synchronize_with Chouette::Sync::Company::Netex
      sync.synchronize_with Chouette::Sync::Network::Netex
      sync.synchronize_with Chouette::Sync::LineNotice::Netex
      sync.synchronize_with Chouette::Sync::Line::Netex
    end
  end

  def line_referential
    @line_referential ||= current_workgroup.line_referential.tap do |line_referential|
      raise ActiveRecord::RecordNotFound unless line_referential.id == params[:id].to_i
    end
  end

  def current_workgroup
    @current_workgroup
  end

  private

  def event_params
    params.require(:line_referential).permit(*permitted_attributes)
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
      *WebhookEvent::LineReferential.resource_names,
      Hash[WebhookEvent::LineReferential.resource_names.map { |name| [name, name.end_with?('s') ? [:id] : {} ] }]
    ]
  end
end
