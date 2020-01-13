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

        log "#{'  ' * indent}#{model.name}#{details}"
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
          build_instance save: true
          register_instance name: instance_name
        end

        children.each(&:create_instance)
      end

      def register_instance(options = {})
        options[:model_name] = model.name
        Array(instance).each do |item|
          registry.register item, options
        end
      end

      def build_instance(options = {})
        self.instance ||=
          if model.count == 1
            model.build_instance self, options
          else
            model.count.times.map do
              model.build_instance self, options
            end
          end
      end

      attr_accessor :model

      def registry
        unless root?
          parent.registry
        else
          @registry ||= Registry.new
        end
      end

      def resolve_instances(values)
        return nil if values.nil?

        if values.respond_to?(:map)
          values.map do |value|
            resolve_instance value
          end
        else
          resolve_instance values
        end
      end

      def resolve_instance(name_or_value)
        if name_or_value.is_a?(Symbol)
          name = name_or_value
          registry.find name: name
        else
          name_or_value
        end
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
              log "Create sub context #{sub_model.name}"
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

      def sub_context_for(model)
        children.find { |context| context.model == model }
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
