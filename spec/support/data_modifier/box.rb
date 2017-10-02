require_relative 'hash'
module Support
  module DataModifier
    module Box
      def next
        raise "Need to implement #{__method__} in #{self.class}"
      end

      class << self
        def unbox atts
          Hash.map_values(atts, method(:value_of))
        end
        def value_of v
          self === v ? v.value : v
        end
      end
    end

  end
end

