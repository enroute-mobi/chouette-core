module Chouette
  class Factory
    class Registry

      def register(instance, attributes = {})
        entries << Entry.new(instance, attributes)
      end

      def entries
        @entries ||= []
      end

      def select(options = {})
        entries.select { |e| e.matches? options }.map!(&:instance)
      end

      def find(options = {})
        matching_instances = select options
        raise Error, "Several Factory instances match this search: #{options.inspect}" if matching_instances.many?
        matching_instances.first
      end

      def find!(options = {})
        instance = find(options)
        raise Error, "No instance matches this search: #{options.inspect}" unless instance
        instance
      end

      def dynamic_model_method(method_name, *arguments)
        model_name = method_name.to_s
        plural = false
        if model_name.ends_with?("s")
          plural = true
          model_name.delete_suffix!("s")
        end

        options = { model_name: model_name }
        options[:name] = arguments.first unless arguments.empty?

        registry_method = plural ? 'select' : 'find'
        instances = send(registry_method, options)

        return instances
      end

      class Entry

        attr_reader :instance, :attributes

        def initialize(instance, attributes = {})
          @instance = instance
          @attributes = attributes
          
          attributes.each do |attribute,value|  
            method = "#{attribute}="
            send method, value if respond_to?(method)
          end
        end

        def matches?(options = {})
          if options[:model_name] && options[:model_name] != model_name
            return false
          end

          options[:name] == name
        end

        attr_accessor :name

        def model_name=(model_name)
          @model_name = model_name.to_s
        end
        def model_name
          @model_name ||= instance.class.model_name.singular
        end
      end

    end
  end
end
