module Chouette
  class Factory
    class Model

      attr_reader :name
      attr_accessor :required, :count
      def initialize(name, options = {})
        @name = name

        {required: false, count: 1}.merge(options).each do |k,v|
          send "#{k}=", v
        end
      end

      alias_method :required?, :required

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

      def around_models=(proc)
        @around_models = proc
      end
      attr_accessor :around_models

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

      def build_attributes(context)
        attributes.each_with_object({}) do |(name, attribute), evaluated|
          evaluated[name] = attribute.evaluate(context)
        end
      end

      def build_instance(context, parent = nil)
        puts "Create #{name} #{klass.inspect} in #{context}"

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
                parent.send(name.to_s.pluralize).build attributes_values
              end
            else
              klass.new attributes_values
            end

          models.each do |_, model|
            if model.required?
              model.count.times do
                model.build_instance(Context.new(model, context.with_instance(new_instance)), new_instance)
              end
            end
          end

          after_callbacks.each do |after_callback|
            after_dsl = AfterDSL.new(self, new_instance, context)

            if after_callback.arity > 0
              after_callback.call new_instance
            else
              after_dsl.instance_eval &after_callback
            end
          end

          unless new_instance.valid?
            puts "Invalid instance: #{new_instance.inspect} #{new_instance.errors.inspect}"
          end

          puts "Created #{new_instance.inspect}"
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

        def around_models(&block)
          @model.around_models = block
        end

      end

      class AfterDSL

        attr_reader :model, :new_instance, :context

        def initialize(model, new_instance, context)
          @model, @new_instance, @context = model, new_instance, context
        end

        def transient(name)
          model.transients[name.to_sym].evaluate(context)
        end

        def parent
          context.parent.instance
        end

      end
    end
  end
end
