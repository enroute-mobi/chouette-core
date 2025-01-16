# frozen_string_literal: true

module Query
  class BookingArrangement < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where(name.matches("%#{value}%"))
      end
    end
  end
end
