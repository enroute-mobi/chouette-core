module Chouette
  class Factory
    class DSL

      def initialize(context)
        @context = context
      end

      def method_missing(name, *arguments, &block)
        sub_context = @context.create name
        super unless sub_context

        if Symbol === arguments.first
          sub_context.instance_name, sub_context.attributes = arguments
        else
          sub_context.attributes = arguments.first
        end
        sub_context.evaluate &block if block_given?
      end

    end
  end
end
