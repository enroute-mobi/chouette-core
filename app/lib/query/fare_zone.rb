module Query
  class FareZone < Base
    def name(value)
      where(value, :matches, :name)
    end

    def fare_provider_id(value)
      change_scope(if: value.present?) do |scope|
        scope.where(fare_provider_id: value)
      end
    end
  end
end
