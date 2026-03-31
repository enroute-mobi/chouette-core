# frozen_string_literal: true

module Scope
  module Export
    class Stateful < Base
      LOADED_CLASSES = [Chouette::VehicleJourney, Chouette::TimeTable]

      def initialize(export_id = nil)
        super()
        @export_id = export_id
        @loaders = {}
      end
      attr_reader :export_id, :loaders

      LOADED_CLASSES.each do |loaded_class|
        collection loaded_class.model_name.collection.to_sym do
          loader(loaded_class, current_collection).loaded_models
        end
      end

      def loader(model_class, current_collection)
        @loaders[model_class] ||= Loader.new(current_collection, export_id, model_class)
      end

      class Loader
        def initialize(current_collection, export_id, loaded_class)
          @current_collection = current_collection
          @export_id = export_id
          @loaded_class = loaded_class
        end
        attr_reader :export_id, :current_collection, :loaded_class

        def loaded_models
          unless @loaded
            columns = %w[uuid export_id model_type model_id].reject do |c|
              c == 'export_id' && export_id.nil?
            end.join(',')
            constants = ["'#{uuid}'", export_id, "'#{loaded_class_name}'"].compact
            models = current_collection.select(constants, :id)

            if sql = models.to_sql.presence
              query = <<~SQL
                INSERT INTO public.exportables (#{columns}) #{sql}
              SQL
              result = ActiveRecord::Base.connection.execute query
              Rails.logger.info "Created #{result.cmd_tuples} #{loaded_class_name} exportables"

              ActiveRecord::Base.connection.execute 'ANALYZE public.exportables'
            end

            @loaded = true
          end

          exportable_models
        end

        def exportable_models
          @exportable_models ||= loaded_class.joins(:exportables).where(exportables: {uuid: uuid, processed: false})
        end

        private

        def loaded_class_name
          @loaded_class_name ||= loaded_class.name
        end

        def uuid
          @uuid ||= SecureRandom.uuid
        end
      end
    end
  end
end
