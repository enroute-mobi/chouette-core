# frozen_string_literal: true

module Types
  class Period < Types::BaseScalar
    description 'A date range'

    def self.coerce_result(value, _context)
      { 'from' => value.from, 'to' => value.to }
    end
  end
end
