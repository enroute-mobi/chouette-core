module Chouette
  module Sync
    class Deleter

      def initialize(options = {})
        options.reverse_merge!(delete_batch_size: 1000)
        options.each { |k,v| send "#{k}=", v }
      end

      attr_accessor :target, :delete_batch_size
      attr_accessor :model_type, :model_id_attribute, :code_space

      attr_reader :delete_count
      include Event::HandlerSupport

      def delete(resource_ids)
        resource_ids.each_slice(delete_batch_size) do |identifiers|
          delete_all existing_models(identifiers)
          event_handler.event :delete, count: identifiers.count
        end
      end

      def delete_from(*updaters)
        # Prevent to remove all resources when no resource was seen in the synchronisation
        return if updaters.map(&:processed_identifiers).all?(&:empty?)

        useless_identifiers = Set.new(existing_identifiers)
        updaters.each do |updater|
          useless_identifiers.subtract updater.processed_identifiers
        end
        delete useless_identifiers
      end

      def use_code?
        (code_space && !code_space.default?) || model_id_attribute == :codes
      end

      protected

      def scope
        @scope ||= target.send(model_type.to_s.pluralize)
      end

      def existing_models(identifiers = nil)
        if identifiers
          if use_code?
            scope.by_code(code_space, identifiers)
          else
            scope.where(model_id_attribute => identifiers)
          end
        else
          if use_code?
            scope.without_code(code_space)
          else
            scope.where.not(model_id_attribute => nil)
          end
        end
      end

      def existing_identifiers
        if use_code?
          code_space.codes.where(resource: existing_models).pluck(:value)
        else
          existing_models.distinct(model_id_attribute).pluck(model_id_attribute)
        end
      end

      # To be customized
      def delete_all(deleted_scope)
        deleted_scope.delete_all
      end

    end
  end
end
