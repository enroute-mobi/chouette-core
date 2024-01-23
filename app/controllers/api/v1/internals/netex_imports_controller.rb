# frozen_string_literal: true

module Api
  module V1
    module Internals
      class NetexImportsController < Api::V1::Internals::BaseController
        include ControlFlow
        include Downloadable

        before_action :find_workbench, only: :create

        def create
          creator = NetexImportCreator.new(@workbench, netex_import_params).create
          render json: creator
        end

        def notify_parent
          find_netex_import
          if @netex_import.notify_parent
            date = I18n.l(@netex_import.notified_parent_at)
            render json: {
              status: 'ok',
              message: "#{@netex_import.parent_type} (id: #{@netex_import.parent_id}) successfully notified at #{date}"
            }
          else
            render json: { status: 'error', message: @netex_import.errors.full_messages }
          end
        end

        def download
          find_netex_import
          prepare_for_download @netex_import
          send_file @netex_import.file.path
        end

        private

        def find_netex_import
          @netex_import = Import::Netex.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: 'error',
            message: 'Record not found'
          }
          finish_action!
        end

        def find_workbench
          @workbench = Workbench.find(netex_import_params['workbench_id'])
        rescue ActiveRecord::RecordNotFound
          render json: { errors: { 'workbench_id' => 'missing' } }, status: :not_acceptable
          finish_action!
        end

        def netex_import_params
          params
            .require('netex_import')
            .permit(:file, :name, :workbench_id, :parent_id, :parent_type)
        end
      end
    end
  end
end
