# frozen_string_literal: true

module Scope
  class FromStopAreas < Base
    collection :stop_area_groups do
      current_collection.where(
        id: ::StopAreaGroup::Member.where(stop_area_id: global_scope.stop_areas.select(:id).distinct)
                                   .select(:group_id)
                                   .distinct
      )
    end

    collection :entrances do
      current_collection.where(stop_area: global_scope.stop_areas)
    end

    collection :fare_zones do
      current_collection.where(
        id: ::Fare::StopAreaZone.where(stop_area_id: global_scope.stop_areas.select(:id).distinct)
                                .select(:fare_zone_id)
                                .distinct
      )
    end
  end
end
