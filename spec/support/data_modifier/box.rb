module Support
  module DataModifier
    module Box
      def next
        raise "Need to implement #{__method__} in #{self.class}"
      end

      class << self
        def unbox atts
          atts.inject Hash.new do | h, (k,v) |
            h.merge(k => value_of(v))
          end
        end
        def value_of v
          self === v ? v.value : v
        end
      end
    end

  end
end

