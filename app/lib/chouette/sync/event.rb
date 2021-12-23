#
#
# Create or update:
#
# Chouette::Sync::Event.new(:create, model: stop_area, resource: gtfs_stop)
# Chouette::Sync::Event.new(:create, model: stop_area, resource: netex_resource, errors: {codes: [{error: :invalid_code_space, value: "dummy"}] })
# Chouette::Sync::Event.new(:create, model: stop_area, resource: netex_resource) unless stop_area.valid?
#
# Delete:
#
# Chouette::Sync::Event.new(:delete, count: 283975)
# Chouette::Sync::Event.new(:delete, errors: {base: :model_in_use }, model: stop_area)

module Chouette
  module Sync
    class Event
      attr_reader :type, :count, :model, :resource
      def initialize(type, **attributes)
        self.type = ActiveSupport::StringInquirer.new(type.to_s)
        attributes.reverse_merge! count: 1, errors: {}
        attributes.each { |k,v| send "#{k}=", v }
      end

      def errors
        if model
          @all_errors ||= @errors.merge(model.errors.details)
        else
          @errors
        end
      end

      def has_error?
        errors.present?
      end

      protected

      attr_writer :type, :count, :model, :resource, :errors

      class Handler
        def initialize(&block)
          @block = block
        end

        def event(event_or_type, **attributes)
          event =
            unless event_or_type.is_a?(Event)
              Event.new(event_or_type, **attributes)
            else
              event_or_type
            end

          handle(event)
        end

        protected

        def handle(event)
          Rails.logger.debug { "Broadcast Synchronization Event #{event.inspect}" }

          @block.call event if @block
        end
      end

      module HandlerSupport
        extend ActiveSupport::Concern

        included do
          attr_writer :event_handler
        end

        def event_handler
          @event_handler ||= Event::Handler.new
        end
      end
    end
  end
end
