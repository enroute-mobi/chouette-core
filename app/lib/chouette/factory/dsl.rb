module Chouette
  class Factory
    class Dsl

      def initialize(context)
        @context = context
      end

      def method_missing(name, *arguments, &block)
        sub_context = @context.define name
        super unless sub_context

        if arguments.first.is_a?(Symbol)
          sub_context.instance_name, sub_context.attributes = arguments
        else
          sub_context.attributes = arguments.first
        end
        sub_context.evaluate(&block) if block_given?
      end

    end
  end
end
