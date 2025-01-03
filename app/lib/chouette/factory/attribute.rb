module Chouette
  class Factory
    class Attribute

      attr_reader :name, :value, :evaluated_value
      def initialize(name, value)
        @name, @value = name, value
        @sequence_number = 0
      end

      def sequence_number
        @sequence_number += 1
      end

      def evaluate(context)
        @evaluated_value =
          if context.attributes.has_key?(name)
            # To support nil or false values
            context_value = context.attributes[name]
            context.resolve_instances context_value
          else
            if value.is_a?(Proc)
              if value.arity == 0
                Dsl.new(context).instance_eval(&value)
              else
                value.call sequence_number
              end
            else
              value
            end
          end
      end

      class Dsl

        def initialize(context)
          @context = context
          @sequence_number = 0
        end

        def parent
          @context.parent.instance
        end

        def build_model(name)
          @context.build_model name
        end

        def build_root_model(name)
          @context.root.build_model name
        end

        def sequence_number
          @sequence_number += 1
        end

      end

    end
  end
end
