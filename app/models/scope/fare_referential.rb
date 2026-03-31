# frozen_string_literal: true

module Scope
  class FareReferential < Delegator
    alias line_referential object

    SUPPORTED = %i[
      fare_zones
      fare_products
      fare_validities
    ].freeze
  end
end
