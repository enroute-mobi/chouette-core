module Chouette
  class Factory
    class Context
      include Log

      attr_writer :attributes
      attr_accessor :instance, :instance_name, :parent

      def initialize(model, parent: nil)
        @model, @parent = model, parent
        parent.children << self if parent
      end

      def with_instance(instance)
        clone = self.dup
        clone.instance = instance
        clone
      end

      def with_parent(parent)
        clone = self.dup
        clone.parent = parent
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

      def root
        parent ? parent.root : self
      end

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
          log "Register #{options.inspect}"
          registry.register item, options
        end
      end

      def build_instance(options = {})
        self.instance ||= model.build_instance self, options
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

        if values.respond_to?(:map) && !values.is_a?(Range)
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

      def define(name)
        create model.find(name)
      end

      def create(path)
        log "Prepare context for '#{path.map(&:name).join('>')}' into #{model.name}"

        next_model = path.shift
        user_context = path.empty?

        sub_context = nil

        unless user_context
          log "Reuse existing context for '#{next_model.name}' into #{model.name}"
          sub_context = sub_context_for(next_model)
        end

        if next_model.singleton? && sub_context.nil? && sub_context_for(next_model).present?
          raise SingletonError, "Try to create a second #{next_model.name} into #{model.name}"
        end

        sub_context ||= Context.new(next_model, parent: self)

        if path.empty?
          sub_context
        else
          begin
            sub_context.create path.dup
          rescue SingletonError => e
            log "Singleton detected in sub context '#{next_model.name}' into #{model.name}: #{e.message}"
            log "Create second '#{next_model.name}' into #{model.name} and create '#{path.map(&:name).join('>')}'"
            sub_context = Context.new(next_model, parent: self)
            sub_context.create(path.dup)
          end
        end
      end

      class SingletonError < StandardError; end

      def build_model(name)
        context = self

        loop do
          if model_context = context.define(name)
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
