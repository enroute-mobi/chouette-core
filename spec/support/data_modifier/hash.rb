module Support
  module DataModifier
    module Hash extend self
      def map_values hashy, f=nil, &fn
        raise ArgumentError, "need block or function arg" unless f = fn || f
        hashy.inject({}){ |h, (k,v)| h.merge(k => f.(v)) }
      end
      def first_values ary_hash
        map_values(ary_hash, &:first)
      end
      def last_values ary_hash
        map_values(ary_hash, &:last)
      end
    end
  end
end
