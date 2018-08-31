module Chouette
  module Factory
    class Context

      attr_accessor :instance, :attributes, :parent

      def initialize(model, parent = nil)
        @model, @parent = model, parent
        parent.children << self if parent
      end

      def with_instance(instance)
        clone = self.dup
        clone.instance = instance
        clone
      end

      def path
        @path ||=
          begin
            prefix = "#{parent.path} > " if parent
            "#{prefix}#{@model.name}"
          end
      end

      def to_s
        path
      end

      def evaluate(&block)
        dsl.instance_eval &block
      end

      def dsl
        @dsl ||= DSL.new(self)
      end

      def attributes
        @attributes ||= {}
      end

      delegate :root?, to: :model

      def create_instance
        unless root?
          self.instance = build_instance
          instance.save!
        end

        children.each(&:create_instance)
      end

      def build_instance
        model.build_instance self
      end

      attr_accessor :model

      def children
        @children ||= []
      end

      def create(name)
        path = model.find(name)
        if path
          new_context = self
          path.each do |sub_model|
            new_context = Context.new(sub_model, new_context)
          end
          new_context
        end
      end

      def build_model(name)
        context = self

        loop do
          if model_context = context.create(name)
            return model_context.build_instance
          end

          if context.root?
            raise "Can't build model #{name} from #{self.inspect}"
          end
          context = context.parent
        end
      end

    end
  end
end
