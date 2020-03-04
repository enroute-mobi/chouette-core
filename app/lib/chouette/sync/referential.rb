module Chouette
  module Sync
    class Referential

      attr_reader :target, :options
      def initialize(target, options = {})
        @target, @options = target, options
      end

      def synchronize_with(sync_class)
        sync_classes << sync_class
      end

      def update_or_create
        syncs.each(&:update_or_create)
      end

      def delete(resource_type, deleted_ids)
        syncs.each do |sync|
          if sync.resource_type == resource_type
            sync.delete deleted_ids
          end
        end
      end

      def counts
        counters = syncs.map(&:counters)
        Counters.sum(counters).to_hash
      end

      def synchronize
        syncs.each(&:synchronize)
      end

      def source=(source)
        options[:source] = source
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

    end
  end
end
