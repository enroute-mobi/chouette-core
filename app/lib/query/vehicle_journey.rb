module Query
  class VehicleJourney < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        published_journey_name = scope.arel_table[:published_journey_name]
        objectid = scope.arel_table[:objectid]
        scope.where(published_journey_name.matches("%#{value}%")).or( scope.where(objectid.matches("%#{value}%")) )
      end
    end

    def company(value)
      change_scope(if: value.present?) do |scope|
        scope.with_companies([value])
      end
    end

    def line(value)
      change_scope(if: value.present?) do |scope|
        scope.with_lines([value])
      end
    end

    def time_table(value)
      change_scope(if: value.present?) do |scope|
        scope.with_matching_timetable(value)
      end
    end

    def between_stop_areas(from_stop_area, to_stop_area)
      change_scope(if: (from_stop_area.present? && to_stop_area.present?)) do |scope|
        scope.with_ordered_stop_area_ids(from_stop_area, to_stop_area)
      end

      change_scope(if: (from_stop_area.present? || to_stop_area.present?)) do |scope|
        stop_area_id = from_stop_area || to_stop_area
        scope.with_stop_area_id(stop_area_id)
      end
    end
    
  end
end