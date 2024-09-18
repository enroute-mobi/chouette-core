module Query
  class StopAreaGroup < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where(name.matches("%#{value}%"))
      end
    end

    def stop_areas(value)
      change_scope(if: value.present?) do |scope|
        scope.where stop_areas: value
      end
    end

    def stop_area_provider_id(value)
      where(value, :eq, :stop_area_provider_id)
    end
  end
end
