require_relative 'box'

module Support
    module DataModifier

      class BoolBox
        include Box
        attr_reader :value

        def initialize value
          @value  = value
        end
        def next
          self.class.new(!value)
        end
      end
    end
end
