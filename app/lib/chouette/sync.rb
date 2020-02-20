module Chouette
  module Sync
    class Base

      attr_accessor :source, :target

      def initialize(options = {})
        options.each { |k,v| send "#{k}=", v }
      end

      def synchronize
        update_or_create
        delete_after_update_or_create
      end

      def update_or_create
        updater.update
      end

      def delete(resource_identifiers)
        deleter.delete resource_identifiers
      end

      protected

      def delete_after_update_or_create
        deleter.delete_from(updater)
      end

      def updater_class
        @updater_class ||= "Chouette::Sync::#{model_class_name}::Updater".constantize
      end

      def deleter_class
        @deleter_class ||= "Chouette::Sync::#{model_class_name}::Deleter".constantize
      end

      # Chouette::Sync::Test -> Test
      # Chouette::Sync::StopArea::Netex -> StopArea
      def model_class_name
        @model_class_name ||= self.class.name.split("::").third
      end

      def updater
        @updater ||= updater_class.new source: source, target: target
      end

      def deleter
        @deleter ||= deleter_class.new target: target
      end

    end
  end
end
