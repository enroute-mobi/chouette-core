# frozen_string_literal: true

module Api
  module V1
    class ImportsController < Api::V1::WorkbenchController
      FILE_TYPE = {
        'netex' => 'netex_generic',
        'shapefile' => 'shape_file',
        'automatic' => 'automatic'
      }.freeze

      respond_to :json, only: %i[show index create]

      def create
        args = workbench_import_params.merge(creator: 'Webservice')

        if current_workbench.organisation.has_feature?('import_netex_force_override_objectid')
          args[:override_internal_identifiers] = 'true'
        end

        args = process_options(args)

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
          file_type: import.import_category,
          created_at: import.created_at,
          updated_at: import.updated_at,
          started_at: import.started_at,
          ended_at: import.ended_at,
          creator: import.creator,
          options: {
            automatic_merge: import.automatic_merge,
            archive_on_fail: import.archive_on_fail,
            flag_urgent: import.flag_urgent,
            import_category: import.import_category
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
        permitted_keys << { options: %w[automatic_merge archive_on_fail flag_urgent file_type] }
        params.require(:workbench_import).permit(permitted_keys)
      end

      private

      def process_options(args)
        if options = args.delete('options').presence
          value = options.delete('file_type')
          args[:import_category] = FILE_TYPE[value] || value
          args['options'] = options
        end

        args
      end
    end
  end
end
