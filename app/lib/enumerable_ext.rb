# frozen_string_literal: true

module Enumerable
  # Returns true if all items are already sorted
  def sorted?
    each_cons(2).all? { |a, b| (a <=> b) <= 0 }
  end
end
