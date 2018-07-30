module Chouette
  module Factory
    class Model

      attr_reader :name
      attr_accessor :required, :count
      def initialize(name, options = {})
        @name = name

        {required: false}.merge(options).each do |k,v|
          send "#{k}=", v
        end
      end

      def define(&block)
        dsl.instance_eval &block
      end

      def dsl
        @dsl ||= DSL.new(self)
      end

      def attributes
        @attributes ||= {}
      end

      def models
        @models ||= {}
      end

      def transients
        @transients ||= {}
      end

      def after_callbacks
        @after_callbacks ||= []
      end

      def root?
        @name == :root
      end

      def klass
        return if root?

        @class_model ||=
          begin
            base_class_name = name.to_s.classify
            candidates = ["Chouette::#{base_class_name}", base_class_name]
            candidates.map { |n| n.constantize rescue nil }.compact.first
          end
      end

      def find(name)
        if model = models[name]
          return [model]
        else
          models.each do |model_name, m|
            path = m.find name
            return [m, *path] if path
          end
        end

        nil
      end

      class Attribute

        attr_reader :name, :value
        def initialize(name, value)
          @name, @value = name, value
        end

      end

      class DSL

        def initialize(model)
          @model = model
        end

        def attribute(name, value = nil, &block)
          @model.attributes[name] = Attribute.new(name, value || block)
        end

        def model(name, options = {}, &block)
          model = @model.models[name] = Model.new(name, options)
          model.define(&block) if block_given?
        end

        def transient(name, value = nil, &block)
          @model.transients[name] = Attribute.new(name, value || block)
        end

        def after(&block)
          @model.after_callbacks << block
        end

      end
    end
  end
end
