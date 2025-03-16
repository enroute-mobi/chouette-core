# frozen_string_literal: true

module Export
  class Part < Operation::Part
    alias export operation

    delegate :target, :export_scope, :workgroup, :code_provider, :cache_key_provider, to: :export

    def decorate(model, **attributes)
      decorator_class = attributes.delete(:with) || default_decorator_class

      attributes = attributes.merge(code_provider: code_provider, decorator_builder: self, **decorator_attributes)
      decorator_class.new model, **attributes
    end

    def default_decorator_class
      @default_decorator_class ||= self.class.const_get('Decorator')
    end

    def decorator_attributes
      {}
    end

    def create_messages(decorator_or_messages)
      messages, decorator = if decorator_or_messages.respond_to?(:messages)
                              [decorator_or_messages.messages, decorator_or_messages]
                            else
                              [decorator_or_messages, nil]
                            end

      messages.each do |message|
        export.messages.create(
          criticity: message.criticity,
          message_key: message.message_key,
          message_attributes: {
            name: decorator&.name
          }.merge(message.message_attributes).compact
        )
      end
    end
  end
end
