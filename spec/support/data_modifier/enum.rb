require_relative 'box'

module Support
    module DataModifier

      class EnumBox
        include Box
        attr_reader :value, :values

        def initialize *enum_values
          @values = enum_values
          @value  = @values.first
        end
        def next
          self.class.new(*(@values[1..-1] << @values.first))
        end
      end
    end
end
