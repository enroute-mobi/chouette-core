module Chouette
  module Sync
    class Base

      attr_accessor :source, :target, :default_provider
      attr_accessor :delete_batch_size, :update_batch_size
      attr_accessor :resource_type, :resource_id_attribute, :resource_decorator
      attr_accessor :model_type, :model_id_attribute, :code_space

      mattr_accessor :default_model_id_attribute, default: :registration_number
      include Event::HandlerSupport

      def initialize(options = {})
        default_options = {
          model_id_attribute: default_model_id_attribute
        }
        options.reverse_merge!(default_options)
        options.each { |k,v| send "#{k}=", v }
      end

      def synchronize
        update_or_create
        delete_after_update_or_create

        after_synchronisation
      end

      def update_or_create
        updater.update_or_create
      end

      def delete(resource_identifiers)
        deleter.delete resource_identifiers
      end

      # To be overrided
      def after_synchronisation; end

      protected

      def delete_after_update_or_create
        deleter.delete_from(updater)
      end

      def updater_class
        @updater_class ||=
          begin
            "Chouette::Sync::#{model_class_name}::Updater".constantize
          rescue NameError
            Chouette::Sync::Updater
          end
      end

      def deleter_class
        @deleter_class ||=
          begin
            "Chouette::Sync::#{model_class_name}::Deleter".constantize
          rescue NameError
            Chouette::Sync::Deleter
          end
      end

      # Chouette::Sync::Test -> Test
      # Chouette::Sync::StopArea::Netex -> StopArea
      def model_class_name
        @model_class_name ||= self.class.name.split("::").third
      end

      # When subclasses needs to create several updaters
      def new_updater(options = {})
        default_options = {
          source: source, target: target,
          update_batch_size: update_batch_size,
          resource_type: resource_type, resource_id_attribute: resource_id_attribute,
          resource_decorator: resource_decorator,
          model_type: model_type, model_id_attribute: model_id_attribute,
          event_handler: event_handler,
          code_space: code_space,
          default_provider: default_provider,
        }.delete_if { |_,v| v.nil? }
        options = default_options.merge(options)
        updater_class.new options
      end

      def updater
        @updater ||= new_updater
      end

      def deleter
        options = {
          target: target,
          delete_batch_size: delete_batch_size,
          model_type: model_type, model_id_attribute: model_id_attribute,
          event_handler: event_handler,
          code_space: code_space,
        }.delete_if { |_,v| v.nil? }

        @deleter ||= deleter_class.new options
      end

    end
  end
end
