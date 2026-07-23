# frozen_string_literal: true

module Query
  class Equipement < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        public_code = scope.arel_table[:public_code]
        scope.where(name.matches("%#{value}%"))
             .or(scope.where(public_code.matches("%#{value}%")))
      end
    end

    def stop_area_id(value)
      where(value, :eq, :stop_area_id)
    end

    def shape_provider_id(value)
      where(value, :eq, :shape_provider_id)
    end

    def fixed(value)
      boolean_where(:fixed, value)
    end

    def out_of_order(value)
      boolean_where(:out_of_order, value)
    end

    private

    # Query::Base#where skips false values (`false.present?` is false), so a
    # boolean filter set to "no" would be ignored. Apply the filter whenever a
    # value is present, including false.
    def boolean_where(column, value)
      change_scope(if: !value.nil?) do |scope|
        scope.where(column => value)
      end
    end
  end
end
