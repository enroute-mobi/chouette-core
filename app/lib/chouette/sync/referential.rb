module Chouette
  module Sync
    class Referential

      attr_reader :target, :options
      def initialize(target, options = {})
        @target, @options = target, options
      end
      attr_accessor :source, :code_space

      def synchronize_with(sync_class)
        sync_classes << sync_class
      end

      def update_or_create
        syncs.each do |sync|
          sync.code_space = code_space
          sync.update_or_create
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
        options.merge(target: target, source: source, code_space: code_space)
      end

      def create_sync(sync_class)
        sync_class.new sync_options
      end
    end
  end
end
