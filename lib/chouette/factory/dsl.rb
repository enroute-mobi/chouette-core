module Chouette
  module Factory
    class DSL

      def initialize(context)
        @context = context
      end

      def method_missing(name, *arguments, &block)
        sub_context = @context.create name
        super unless sub_context
        sub_context.attributes = arguments.first
        sub_context.evaluate &block if block_given?
      end

    end
  end
end
