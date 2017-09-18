module Support
  module Helpers
    module DataModifier
      module Value
        def next
          raise "Need to implement #{__method__} in #{self.class}"
        end
      end

      class Enum
        include Value
        attr_reader :value, :values

        def initialize *enum_values
          @values = enum_values.flatten
          @value  = @values.first
        end
        def next
          self.class.new(@values[1..-1], @values.first)
        end
      end
      
      def make_enum *enum_values
        Enum.new enum_values
      end
      def strip_values atts
        atts.inject Hash.new do | h, (k,v) |
          h.merge(k => value_of(v))
        end
      end
      def value_of v
        Value === v ? v.value : v
      end
    end
  end
end
