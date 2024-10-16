# frozen_string_literal: true

module Query
  class VehicleJourney < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        column_names = column_names(scope)
        custom_scope = scope.select(*column_names).from(custom_from(scope, column_names)).distinct

        published_journey_name = custom_scope.arel_table[:published_journey_name]
        published_journey_identifier = custom_scope.arel_table[:published_journey_identifier]
        objectid = custom_scope.arel_table[:objectid]
        code = custom_scope.arel_table[:code]
        custom_scope = custom_scope.where(published_journey_name.matches("%#{value}%"))
                                   .or(custom_scope.where(objectid.matches("%#{value}%")))
                                   .or(custom_scope.where(published_journey_identifier.matches("%#{value}%")))
                                   .or(custom_scope.where(code.matches("%#{value}%")))
        ids = scope.select(:id).from("(#{custom_scope.to_sql}) AS vehicle_journeys")

        scope.where(id: ids)
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
        scope.with_time_tables([value])
      end
    end

    def time_table_period(value)
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

    private

    def custom_from(scope, column_names)
      select = column_names + ["code_spaces.short_name || ':' || referential_codes.value AS code"]
      "(#{scope.left_joins(codes: :code_space).select(*select).to_sql}) AS #{scope.table_name}"
    end

    def column_names(scope)
      scope.column_names.map { |c| "#{scope.table_name}.#{c}" }
    end
  end
end