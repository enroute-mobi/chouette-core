module Chouette
  module Sync
    class Deleter

      def initialize(options = {})
        options.reverse_merge!(delete_batch_size: 1000)
        options.each { |k,v| send "#{k}=", v }
      end

      attr_accessor :target, :delete_batch_size
      attr_accessor :model_type, :model_id_attribute

      attr_reader :delete_count
      include Event::HandlerSupport

      def delete(resource_ids)
        resource_ids.each_slice(delete_batch_size) do |identifiers|
          delete_all existing_models(identifiers)
          event_handler.event :delete, count: identifiers.count
        end
      end

      def delete_from(*updaters)
        useless_identifiers = Set.new(existing_identifiers)
        updaters.each do |updater|
          useless_identifiers.subtract updater.processed_identifiers
        end
        delete useless_identifiers
      end

      protected

      def scope
        @scope ||= target.send(model_type.to_s.pluralize)
      end

      def existing_models(identifiers = nil)
        if identifiers
          scope.where(model_id_attribute => identifiers)
        else
          scope.where.not(model_id_attribute => nil)
        end
      end

      def existing_identifiers
        existing_models.distinct(model_id_attribute).pluck(model_id_attribute)
      end

      # To be customized
      def delete_all(deleted_scope)
        deleted_scope.delete_all
      end

    end
  end
end
