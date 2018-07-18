class Range

  def intersection(other)
    return nil unless intersect?(other)
    [self.min, other.min].max..[self.max, other.max].min
  end
  alias_method :&, :intersection

  def intersect?(other)
    self.max >= other.min and other.max >= self.min
  end

  def remove(other)
    return self if (self.max < other.min or other.max < self.min)

    [].tap do |remaining|
      remaining << (self.min..other.min-1) if self.min < other.min
      remaining << (other.max+1..self.max) if other.max < self.max
      remaining.compact!
    end
  end
  alias_method :-, :remove

end
