# frozen_string_literal: true

module Scope
  class LineReferential < Delegator
    alias line_referential object

    SUPPORTED = %i[
      lines
      line_groups
      companies
      networks
      line_notices
      booking_arrangements
    ].freeze
  end
end
