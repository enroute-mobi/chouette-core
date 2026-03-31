# frozen_string_literal: true

module Scope
  class ShapeReferential < Delegator
    alias shape_referential object

    SUPPORTED = %i[
      shapes
      point_of_interests
    ].freeze
  end
end
