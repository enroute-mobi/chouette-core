module Chouette
  module Sync
    class Deleter

      def initialize(options = {})
        options.reverse_merge!(delete_batch_size: 1000)
        options.each { |k,v| send "#{k}=", v }

        @delete_count = 0
      end

      attr_accessor :target, :delete_batch_size
      attr_accessor :model_type, :model_id_attribute

      attr_reader :delete_count

      def delete(resource_ids)
        resource_ids.each_slice(delete_batch_size) do |identifiers|
          delete_all existing_models(identifiers)
          increment_count identifiers.count
        end
      end

      def delete_from(*updaters)
        useless_identifiers = Set.new(existing_identifiers)
        updaters.each do |updater|
          useless_identifiers.substract updater.processed_identifiers
        end
        delete useless_identifiers
      end

      protected

      def increment_count(count)
        @delete_count += count
      end

      def scope
        @scope ||= target.send("#{model_type}s")
      end

      def existing_models(identifiers)
        scope.where(model_id_attribute => identifiers)
      end

      def existing_identifiers
        scope.where.not(model_id_attribute => nil).distinct.pluck(model_id_attribute)
      end

      # To be customized
      def delete_all(scope)
        scope.delete_all
      end

    end
  end
end
