# frozen_string_literal: true

module Export
  class Decorator < SimpleDelegator
    def initialize(model, **attributes)
      super model

      attributes.each { |k, v| send "#{k}=", v }
    end

    def model
      __getobj__
    end

    def model_code
      @model_code ||= code_provider.code(model)
    end

    attr_writer :code_provider

    def code_provider
      @code_provider ||= Export::CodeProvider.null
    end

    attr_accessor :decorator_builder

    def decorate(model, **attributes)
      return decorator_builder.decorate(model, **attributes) if decorator_builder

      # Basic implementation for test
      decorator_class = attributes.delete(:with) || self.class
      decorator_class.new(model, **attributes.merge(code_provider: code_provider))
    end

    def messages
      @messages ||= Messages.new
    end

    def validate
    end

    def valid?
      messages.clear
      validate
      messages.empty?
    end

    class Messages < SimpleDelegator
      def initialize
        @messages = []
        super @messages
      end

      def add(message_key, **attributes)
        @messages << Message.new(message_key, **attributes)
      end
    end

    class Message
      attr_accessor :message_key, :criticity
      attr_writer :message_attributes

      def initialize(message_key, **attributes)
        @message_key = message_key

        attributes.each { |k,v| send "#{k}=", v }
      end

      def criticity
        @criticity ||= :warning
      end

      def message_attributes
        @message_attributes ||= {}
      end
    end
  end
end
