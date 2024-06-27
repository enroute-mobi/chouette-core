module Chouette
  class Factory
    class Model
      include Log

      attr_reader :name
      attr_writer :association_name
      attr_accessor :required, :singleton, :save_options, :around_models

      def initialize(name, options = {})
        @name = name

        { required: false, singleton: false, save_options: {} }.merge(options).each do |k, v|
          send "#{k}=", v
        end
      end

      def association_name
        @association_name ||= name.to_s.pluralize
      end

      alias required? required
      alias singleton? :singleton

      def define(&block)
        dsl.instance_exec(&block)
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
          models.each do |_, m|
            path = m.find name
            return [m, *path] if path
          end
        end

        nil
      end

      def build_attributes(context)
        attributes_values = attributes.each_with_object({}) do |(name, attribute), evaluated|
          evaluated[name] = attribute.evaluate(context)
        end

        context.attributes.each do |name, value|
          unless transients[name]
            attributes_values[name] ||= context.resolve_instances value
          end
        end

        attributes_values
      end

      def build_instance(context, options = {})
        options = { parent: nil, save: false }.update(options)

        parent = options[:parent]
        save = options[:save]

        log "#{save ? 'Create' : 'Build'} #{name} #{klass.inspect} in #{context}"

        attributes_values = build_attributes(context)
        parent ||= context.parent.instance

        new_instance = nil

        context.parent.around_models do
          new_instance =
            if parent
              # Try Parent#build_model
              if parent.respond_to?("build_#{name}")
                parent.send("build_#{name}", attributes_values)
              else
                # Then Parent#models
                parent.send(association_name).build attributes_values
              end
            else
              klass.new attributes_values
            end

          models.each do |_, model|
            if model.required?
              # TODO with_instance for sub_context_for ?
              sub_context = context.sub_context_for(model) ||
                            Context.new(model, parent: context.with_instance(new_instance))
              # sub_context = context.sub_context_for(model) || Context.new(model)
              # sub_context = sub_context.with_parent(context.with_instance(new_instance))

              sub_context.build_instance parent: new_instance
            end
          end

          after_callbacks.each do |after_callback|
            after_dsl = AfterDSL.new(self, new_instance, context.with_instance(new_instance))
            after_dsl.instance_exec(new_instance, &after_callback)
          end
          unless new_instance.valid?
            log "Invalid instance: #{new_instance.inspect} #{new_instance.errors.inspect}"
          end

          new_instance.save!(**save_options) if save

          log "#{save ? 'Created' : 'Built'} #{new_instance.inspect}"
        end

        new_instance
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

        def save_options(save_options)
          @model.save_options = save_options
        end

        def around_models(&block)
          @model.around_models = block
        end

      end

      class AfterDSL

        attr_reader :model, :new_instance, :context

        def initialize(model, new_instance, context)
          @model, @new_instance, @context = model, new_instance, context
        end

        def transient(name, resolve_instances: false)
          values = model.transients[name.to_sym].evaluate(context)

          if resolve_instances
            values = context.resolve_instances(values)
          end

          values
        end

        def parent
          context.parent.instance
        end

        def build_model(name)
          context.build_model name
        end

      end
    end
  end
end
