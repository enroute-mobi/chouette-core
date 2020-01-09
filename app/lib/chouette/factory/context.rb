module Chouette
  class Factory
    class Context
      include Log

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

      def debug(indent = 0)
        details = instance_name ? " #{instance_name.inspect}" : ""
        details += " #{attributes.inspect}" unless attributes.empty?

        puts "#{'  ' * indent}#{model.name}#{details}"
        children.each do |child|
          child.debug indent+1
        end
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
        dsl.instance_eval(&block)
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
          self.instance = model.build_instance self, save: true

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

      def resolve_instances(values)
        return nil if values.nil?

        if values.respond_to?(:map)
          values.map do |value|
            if value.is_a?(Symbol)
              resolve_instance value
            else
              value
            end
          end
        else
          resolve_instance values
        end
      end

      def resolve_instance(name)
        named_instances.fetch name
      end

      def children
        @children ||= []
      end

      def implicit_contexts
        @implicit_contexts ||= {}
      end

      def create(name)
        path = model.find(name)
        if path
          log "Create context for '#{name}' (#{path.map(&:name).join(' > ')})"
          new_context = self
          path.each_with_index do |sub_model, position|
            implicit_path = nil
            next_model = nil
            if position < (path.length-1)
              implicit_path = path[0..position].map(&:name).join('>')
              next_model = path[position+1]
            end

            if !implicit_contexts.has_key?(implicit_path) or next_model&.singleton?
              new_context = Context.new(sub_model, new_context)
            else
              log "Reuse implicit context #{implicit_path}"
              new_context = implicit_contexts[implicit_path]
            end

            if implicit_path && !implicit_contexts.has_key?(implicit_path)
              log "Save implicit context #{implicit_path}"
              implicit_contexts[implicit_path] = new_context
            end
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
          log "Around models in #{self}"
          parent.around_models do
            local_models_proc = model.around_models
            if local_models_proc
              log "local_models_proc: #{local_models_proc.inspect} with #{instance.inspect}"
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
