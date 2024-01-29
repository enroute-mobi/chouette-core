# frozen_string_literal: true

module Api
  module V1
    class StopAreaReferentialsController < WorkbenchController
      respond_to :json, :xml
      wrap_parameters :stop_area_referential, include: [:type, *WebhookEvent::StopAreaReferential.resource_names]

      before_action :authenticate

      def webhook
        if event.valid?
          if event.update_or_create?
            synchronization.source = event.netex_source
            synchronization.update_or_create
          end

          if event.destroyed?
            deleted_ids = event.stop_place_ids + event.quay_ids
            synchronization.delete deleted_ids
          end

          logger.info "Synchronization done: #{counters}"
          render json: counters.to_hash, status: :ok
        else
          render json: { message: event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      protected

      def event
        @event ||= WebhookEvent::StopAreaReferential.new event_params
      end

      def counters
        @counters ||= Chouette::Sync::Counters.new
      end

      def synchronization
        @synchronization ||=
          Chouette::Sync::StopArea::Netex.new target: stop_area_provider, event_handler: counters.event_handler
      end

      def stop_area_provider
        @stop_area_provider ||= workbench.default_stop_area_provider
      end

      def workbench
        @workbench = current_workgroup.workbenches.find(params[:id])
      end

      attr_reader :current_workgroup

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
          'type',
          *WebhookEvent::StopAreaReferential.resource_names,
          Hash[WebhookEvent::StopAreaReferential.resource_names.map { |name| [name, name.end_with?('s') ? [:id] : {}] }]
        ]
      end

      def authenticate
        authenticate_or_request_with_http_token do |token|
          api_key = ApiKey.find_by token: token
          @current_workgroup = api_key&.workgroup

          @current_workgroup.present?
        end
      end
    end
  end
end
