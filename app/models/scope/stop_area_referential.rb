# frozen_string_literal: true

module Scope
  class StopAreaReferential < Delegator
    alias stop_area_referential object

    SUPPORTED = %i[
      stop_areas
      stop_area_groups
      entrances
    ].freeze

    collection :non_flexible_stop_areas do
      stop_area_referential.stop_areas.where(id: global_scope.stop_areas)
                                      .where.not(area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE).or(
        stop_area_referential.stop_areas.where(
          id: global_scope.flexible_stop_areas.select('flexible_area_memberships.member_id')
                                              .joins(:flexible_area_memberships)
                                              .distinct
        )
      )
    end

    collection :flexible_stop_areas do
      global_scope.stop_areas.where(area_type: Chouette::AreaType::FLEXIBLE_STOP_PLACE)
    end
  end
end
