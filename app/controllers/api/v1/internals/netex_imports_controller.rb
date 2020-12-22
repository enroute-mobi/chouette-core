module Api
  module V1
    module Internals
      class NetexImportsController < Api::V1::Internals::ApplicationController
        include ControlFlow

        def create
          respond_to do | format |
            format.json do
              import = create_models
              render json: {
                status: "ok",
                message:"Import ##{import.id} created as child of #{import.parent_type} (id: #{import.parent_id})"
              }
            end
          end
        end

        def notify_parent
          find_netex_import
          if @netex_import.notify_parent
            render json: {
              status: "ok",
              message:"#{@netex_import.parent_type} (id: #{@netex_import.parent_id}) successfully notified at #{l(@netex_import.notified_parent_at)}"
            }
          else
            render json: {status: "error", message: @netex_import.errors.full_messages }
          end
        end

        def download
          find_netex_import
          store_file_and_clean_cache(@netex_import)
          send_file @netex_import.file.path
        end

        private

        def store_file_and_clean_cache(source)
          source.file.cache_stored_file!
          CarrierWave.clean_cached_files!
        end

        def find_netex_import
          @netex_import = Import::Netex.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: {
            status: "error",
            message: "Record not found"
          }
          finish_action!
        end

        def find_workbench
          @workbench = Workbench.find(netex_import_params['workbench_id'])
        rescue ActiveRecord::RecordNotFound
          render json: {errors: {'workbench_id' => 'missing'}}, status: 406
          finish_action!
        end

        def create_models
          find_workbench
          create_netex_import
        end

        def create_netex_import
          attributes = netex_import_params.merge creator: "Webservice"
          @netex_import = Import::Netex.new attributes
          @netex_import.create_with_referential!
          @netex_import
        rescue ActiveRecord::RecordInvalid
          render json: {errors: @netex_import.errors}, status: 406
          finish_action!
        end

        def create_referential
          new_referential =
            Referential.new(
              name: netex_import_params['name'],
              organisation_id: @workbench.organisation_id,
              workbench_id: @workbench.id,
              metadatas: [metadata]
            )
          new_referential.save
          new_referential
        end

        def metadata
          metadata = ReferentialMetadata.new

          if netex_import_params['file']
            netex_file = STIF::NetexFile.new(netex_import_params['file'].to_io)
            frame = netex_file.frames.first

            if frame
              metadata.periodes = frame.periods

              line_objectids = frame.line_refs.map { |ref| "FR1:Line:#{ref}:" }
              metadata.line_ids = @workbench.lines.where(objectid: line_objectids).pluck(:id)
            end
          end

          metadata
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
