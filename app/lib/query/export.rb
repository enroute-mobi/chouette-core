# frozen_string_literal: true

module Query
  class Export < Query::LegacyOperation
    def text(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table
        scope.where(
          table[:name].matches("%#{value}%").or(table[:creator].matches("%#{value}%"))
        )
      end
    end
  end
end
