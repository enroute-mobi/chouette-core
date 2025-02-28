# frozen_string_literal: true

module Export
  class Part < Operation::Part
    alias export operation

    delegate :target, :export_scope, :workgroup, :code_provider, :cache_key_provider, to: :export

    def decorate(model, **attributes)
      decorator_class = attributes.delete(:with) || default_decorator_class

      attributes = attributes.merge(code_provider: code_provider, decorator_builder: self).merge(decorator_attributes)
      decorator_class.new model, **attributes
    end

    def default_decorator_class
      @default_decorator_class ||= self.class.const_get('Decorator')
    end

    def decorator_attributes
      {}
    end
  end
end
