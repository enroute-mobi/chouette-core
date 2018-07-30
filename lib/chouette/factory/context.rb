module Chouette
  module Factory
    class Context

      attr_accessor :instance, :attributes, :parent

      def initialize(model, parent = nil)
        @model, @parent = model, parent
        parent.children << self if parent
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

      def save
        if model.root?
          children.each(&:save)
        else
          instance&.save!
        end
      end

      def build
        unless model.root?
          self.instance = build_instance
          puts instance.inspect
        end
        children.each(&:build)
      end

      def build_instance
        puts "Create #{model.name} #{model.klass.inspect}"

        build_attributes = attributes

        new_instance =
          if parent.model.root?
            model.klass.new build_attributes
          else
            parent_instance = parent.instance

            # Try Parent#model
            if parent_instance.respond_to?("build_#{model.name}")
              parent_instance.send("build_#{model.name}", build_attributes)
            else
              # Then Parent#models
              parent_instance.send(model.name.to_s.pluralize).build build_attributes
            end
          end

        puts parent.instance.inspect
        puts "Created #{new_instance.inspect}"

        new_instance
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

    end
  end
end
