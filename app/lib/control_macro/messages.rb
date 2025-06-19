# frozen_string_literal: true

module ControlMacro
  class Messages
    def initialize(run, message_klass, run_id_attribute, resource_name_key: :name)
      @run = run
      @message_klass = message_klass
      @run_id_attribute = run_id_attribute
      @resource_name_key = resource_name_key
    end
    attr_reader :run, :message_klass, :run_id_attribute, :resource_name_key

    def create(source: nil, **message_attributes)
      message = Message.new(self, source: source, **message_attributes)
      yield message if block_given?
      message_klass.create!(message.attributes.merge!(run_id_attribute => run.id)) # TODO checks presence validation and make a request to macro run that we do not want
    end

    class Message
      def initialize(messages, source: nil, **message_attributes)
        @messages = messages
        @source = source
        @message_attributes = message_attributes
      end
      attr_reader :messages, :source, :message_attributes

      delegate :resource_name_key, to: :messages

      def attributes
        return @attributes if @attributes

        attributes = {
          message_attributes: message_attributes
        }

        if source
          attributes[:source] = source
          attributes[:message_attributes][resource_name_key] ||= source.name if resource_name_key
        end

        @attributes = attributes
      end

      delegate :[], :[]=, to: :attributes

      def error!(criticity: 'error', message_key: 'error')
        attributes[:criticity] = criticity
        attributes[:message_key] = message_key
      end
    end
  end
end
