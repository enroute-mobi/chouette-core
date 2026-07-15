# frozen_string_literal: true

module Query
  class Equipment < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        public_code = scope.arel_table[:public_code]
        objectid = scope.arel_table[:objectid]
        scope.where(name.matches("%#{value}%"))
             .or(scope.where(objectid.matches("%#{value}%")))
             .or(scope.where(public_code.matches("%#{value}%")))
      end
    end

    def stop_area_id(value)
      where(value, :eq, :stop_area_id)
    end

    def stop_area_provider_id(value)
      where(value, :eq, :stop_area_provider_id)
    end

    def fixed(value)
      where(value, :in, :fixed)
    end

    def out_of_order(value)
      where(value, :in, :out_of_order)
    end
  end
end
