# frozen_string_literal: true

module Api
  module V1
    class ImportsController < Api::V1::WorkbenchController
      IMPORT_CATEGORY_ALIASES = {
        'netex' => 'netex_generic',
        'shapefile' => 'shape_file'
      }.freeze

      respond_to :json, only: %i[show index create]

      def create
        @import = current_workbench.workbench_imports.new(import_attributes)

        if @import.flag_urgent && !policy(@import).option_flag_urgent?
          logger.error("Import #{@import.name} uses flag_urgent but workbench #{current_workbench.name} inside organisation #{current_workbench.name} doesn't have permission referentials.flag_urgent")
          @import.flag_urgent = false
        end

        if default_company.present? && @import.specific_default_company.nil?
          @import.errors.add(:specific_default_company_id, :must_exist)
        end

        if @import.errors.empty? && @import.save
          render json: import_json(@import), status: :created
        else
          render json: { status: 'error', messages: @import.errors.full_messages }, status: :unprocessable_entity
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
            default_company: import.specific_default_company&.registration_number
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
        permitted_keys << { options: %w[automatic_merge archive_on_fail flag_urgent file_type default_company] }
        params.require(:workbench_import).permit(permitted_keys)
      end

      def default_company
        @default_company ||= workbench_import_params['options']['default_company']
      end

      def import_attributes
        @import_attributes ||= workbench_import_params.tap do |import_attributes|
          import_attributes.merge!(creator: 'Webservice')

          if current_workbench.organisation.has_feature?('import_netex_force_override_objectid')
            import_attributes['options'] ||= ActionController::Parameters.new.permit!
            import_attributes['options'][:override_internal_identifiers] = 'true'
          end

          if (file_type = import_attributes['options']&.delete('file_type'))
            import_attributes['options'][:import_category] = IMPORT_CATEGORY_ALIASES.fetch(file_type, file_type)
          end

          if default_company
            import_attributes['options'][:specific_default_company_id] =
              current_workbench.companies.find_by(registration_number: default_company)&.id
          end
        end
      end
    end
  end
end
