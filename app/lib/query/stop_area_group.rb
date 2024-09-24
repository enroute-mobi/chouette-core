# frozen_string_literal: true

module Query
  class StopAreaGroup < Base
    def text(value)
      change_scope(if: value.present?) do |scope|
        name = scope.arel_table[:name]
        scope.where(name.matches("%#{value}%"))
      end
    end

    def stop_areas(value)
      value = value.reject(&:blank?) if value.present?
      change_scope(if: value.present?) do |scope|
        scope.joins(:members).where(stop_area_group_members: { stop_area_id: value })
      end
    end

    def stop_area_provider_id(value)
      where(value, :eq, :stop_area_provider_id)
    end
  end
end
