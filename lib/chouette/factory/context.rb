module Chouette
  module Factory
    class Context

      attr_accessor :model, :attributes, :parent

      def initialize(type, parent = nil)
        @type, @parent = type, parent
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
        if type.root?
          children.each(&:save)
        else
          model&.save!
        end
      end

      def build
        unless type.root?
          self.model = build_model
          puts model.inspect
        end
        children.each(&:build)
      end

      def build_model
        puts "Create #{type.name} #{type.class_model.inspect}"

        build_attributes = attributes

        new_model =
          if parent.type.root?
            type.class_model.new build_attributes
          else
            parent_model = parent.model

            # Try Parent#type
            if parent_model.respond_to?("build_#{type.name}")
              parent_model.send("build_#{type.name}", build_attributes)
            else
              # Then Parent#types
              parent_model.send(type.name.to_s.pluralize).build build_attributes
            end
          end

        puts parent.model.inspect
        puts "Created #{new_model.inspect}"

        new_model
      end

      attr_accessor :type

      def children
        @children ||= []
      end

      def create(name)
        path = type.find(name)
        if path
          new_context = self
          path.each do |sub_type|
            new_context = Context.new(sub_type, new_context)
          end
          new_context
        end
      end

    end
  end
end
