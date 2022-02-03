module Chouette
  module Sync
    class Referential

      attr_reader :target, :options, :import
      def initialize(target, options = {})
        @target, @options = target, options
      end

      def synchronize_with(sync_class)
        sync_classes << sync_class
      end

      def update_or_create
        if @import.blank?
          syncs.each(&:update_or_create)
        else
          syncs.each do |sync|
            update_or_create_with_logs(sync)
          end
        end
      end

      def event_handler=(event_handler)
        syncs.each do |sync|
          sync.event_handler = event_handler
        end
      end

      def delete(resource_type, deleted_ids)
        syncs.each do |sync|
          if sync.resource_type == resource_type
            sync.delete deleted_ids
          end
        end
      end

      def synchronize
        syncs.each(&:synchronize)
      end

      def source=(source)
        options[:source] = source
      end

      def import=(import)
        @import = import
      end

      protected

      def sync_classes
        @sync_classes ||= []
      end

      def syncs
        @syncs ||= sync_classes.map do |sync_class|
          create_sync sync_class
        end
      end

      def sync_options
        options.merge(target: target)
      end

      def create_sync(sync_class)
        sync_class.new sync_options
      end

      private

      def create_resource(resource_name)
        @import.resources.build(
          name: resource_name,
          resource_type: resource_name.to_s.pluralize,
          reference: resource_name,
        )
      end

      def update_or_create_with_logs(sync)
        resource = create_resource(sync.model_type)

        event_handler = Chouette::Sync::Event::Handler.new do |event|
          unless event.has_error?
            if event.type.create? || event.type.update?
              resource.status = "OK"
              resource.inc_rows_count event.count
              resource.messages.build(
                criticity: :info,
                message_attributes: {
                  attribute_name: {
                    id: event.model&.id,
                    name: event.model&.name
                  },
                }
              )
            end
          else
            resource.status = "ERROR"
            event.errors.each do |attribute, errors|
              errors.each do |error|
                resource.messages.build(
                  criticity: :error,
                  message_key: :invalid_model_attribute,
                  message_attributes: {
                    attribute_name: attribute,
                    attribute_value: error[:value]
                  }
                )
              end
            end
            @import.status = 'failed'
          end
          resource.save!
        end

        sync.event_handler = event_handler
        sync.update_or_create

        resource.update_metrics
        #resource.save!
      end
    end
  end
end
