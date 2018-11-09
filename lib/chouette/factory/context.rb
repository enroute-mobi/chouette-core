module Chouette
  class Factory
    class Context

      attr_accessor :instance, :instance_name, :attributes, :parent

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

          if instance_name
            named_instances[instance_name] = instance
          end
        end

        children.each(&:create_instance)
      end

      def build_instance
        model.build_instance self
      end

      attr_accessor :model

      def named_instances
        unless root?
          parent.named_instances
        else
          @named_instances ||= {}
        end
      end

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

      def around_models(&block)
        if root?
          block.call
        else
          puts "Around models in #{self}"
          parent.around_models do
            local_models_proc = model.around_models
            if local_models_proc
              puts "local_models_proc: #{local_models_proc.inspect} with #{instance.inspect}"
              local_models_proc.call instance, block
            else
              block.call
            end
          end
        end
      end

    end
  end
end
