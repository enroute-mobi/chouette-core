module Arel
  module Predications
    def between other
      min = other.is_a?(Range) ? other.min : other[0]
      max = other.is_a?(Range) ? other.max : other[1]
      gteq(min).and(lt(max))
    end
  end
end
