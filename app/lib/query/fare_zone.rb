module Query
  class FareZone < Base
    def name(value)
      change_scope(if: value.present?) do |scope|
        table = scope.arel_table
        scope.where(table[:name].matches("%#{value}%"))
      end
    end

    def fare_provider_id(value)
      change_scope(if: value.present?) do |scope|
        scope.where(fare_provider_id: value)
      end
    end
  end
end
