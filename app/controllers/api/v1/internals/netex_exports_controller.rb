module Api
  module V1
    module Internals
      class NetexExportsController < Api::V1::Internals::ApplicationController
        include ControlFlow
        skip_before_action :require_token, only: :upload
        before_action :find_netex_export

        def upload
          if authenticate_token
            @netex_export.file = params[:exportFile]
            @netex_export.ended_at = Time.now
            @netex_export.save!
            @netex_export.successful!
            @netex_export.notify_publication
            render json: {
              status: 'ok',
              message: "File successfully uploaded for #{@netex_export.type} (id: #{@netex_export.id})"
            }
          else
            @netex_export.failed!
            @netex_export.notify_publication
            render_unauthorized('Access denied')
          end
        end

        def notify_parent
          if @netex_export.notify_publication
            render json: { status: 'ok' }
          else
            render json: { status: 'error' }
          end
        end

        private

        def find_netex_export
          @netex_export = Export::Netex.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: 'error',
            message: 'Record not found'
          }, status: 404
          finish_action!
        end
      end
    end
  end
end
