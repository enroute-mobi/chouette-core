# frozen_string_literal: true

module Api
  module V1
    class ImportsController < Api::V1::WorkbenchController
      respond_to :json, only: %i[show index create]

      def create
        args = workbench_import_params.merge(creator: 'Webservice')

        @import = current_workbench.workbench_imports.new(args)

        if @import.flag_urgent && !policy(@import).option_flag_urgent?
          logger.error("Import #{@import.name} uses flag_urgent but workbench #{current_workbench.name} inside organisation #{current_workbench.name} doesn't have permission referentials.flag_urgent")
          @import.flag_urgent = false
        end

        if @import.save
          render json: import_json(@import), status: :created
        else
          render json: { status: 'error', messages: @import.errors.full_messages }
        end
      end

      def index
        render json: imports_map
      end

      def show
        import = current_workbench.workbench_imports.find(params[:id])
        render json: import_json(import)
      end

      private

      def import_json(import)
        {
          id: import.id,
          status: import.status,
          workbench_id: import.workbench_id,
          name: import.name,
          created_at: import.created_at,
          updated_at: import.updated_at,
          started_at: import.started_at,
          ended_at: import.ended_at,
          creator: import.creator,
          options: {
            automatic_merge: import.automatic_merge,
            archive_on_fail: import.archive_on_fail,
            flag_urgent: import.flag_urgent
          }
        }
      end

      def imports_map
        current_workbench.workbench_imports.includes(:children).collect do |import|
          import_json(import)
        end
      end

      def workbench_import_params
        permitted_keys = %i[name file]
        permitted_keys << { options: %w[automatic_merge archive_on_fail flag_urgent] }
        params.require(:workbench_import).permit(permitted_keys)
      end
    end
  end
end
