# frozen_string_literal: true

module Api
  module V1
    class LineReferentialsController < WorkbenchController
      respond_to :json, :xml
      wrap_parameters :line_referential, include: [:type, *WebhookEvent::LineReferential.resource_names]

      layout false
      before_action :authenticate

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

          logger.info "Synchronization done: #{counters}"
          render json: counters.to_hash, status: :ok
        else
          render json: { message: event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      protected

      def event
        @event ||= WebhookEvent::LineReferential.new event_params
      end

      def counters
        @counters ||= Chouette::Sync::Counters.new
      end

      def synchronization
        @synchronization ||= Chouette::Sync::Referential.new(line_provider).tap do |sync|
          sync.synchronize_with Chouette::Sync::Company::Netex
          sync.synchronize_with Chouette::Sync::Network::Netex
          sync.synchronize_with Chouette::Sync::LineNotice::Netex
          sync.synchronize_with Chouette::Sync::Line::Netex

          sync.event_handler = counters.event_handler
        end
      end

      def line_provider
        @line_provider ||= workbench.default_line_provider
      end

      def workbench
        @workbench = current_workgroup.workbenches.find(params[:id])
      end

      attr_reader :current_workgroup

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
          'type',
          *WebhookEvent::LineReferential.resource_names,
          Hash[WebhookEvent::LineReferential.resource_names.map { |name| [name, name.end_with?('s') ? [:id] : {}] }]
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
