module Query
  class Entrance < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        short_name = scope.arel_table[:short_name]
        objectid = scope.arel_table[:objectid]
        scope.where(name.matches("%#{value}%")).or( scope.where(objectid.matches("%#{value}%"))).or( scope.where(short_name.matches("%#{value}%")))
      end
    end

    def entrance_type(value)
      where(value, :in, :entrance_type)
    end

    def stop_area_id(value)
      where(value, :eq, :stop_area_id)
    end

    def zip_code(value)
      where(value, :matches, :zip_code)
    end

    def city_name(value)
      where(value, :matches, :city_name)
    end

    def stop_area_provider_id(value)
      where(value, :eq, :stop_area_provider_id)
    end

    def entry_flag(value)
      where(value, :in, :entry_flag)
    end

    def exit_flag(value)
      where(value, :in, :exit_flag)
    end
  end
end
