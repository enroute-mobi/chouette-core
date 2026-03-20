# frozen_string_literal: true

module Scope
  class FromVehicleJourneys < Base
    def initialize(time_tables: true)
      super()
      @time_tables = time_tables
    end

    def scopes?(name)
      return false if !@time_tables && name == :time_tables

      super
    end

    collection :footnotes do
      current_collection.joins(:vehicle_journeys).where(vehicle_journeys: { id: global_scope.vehicle_journeys })
    end

    collection :lines do
      current_collection.where(id: global_scope.routes.select(:line_id).distinct)
    end

    collection :line_notices do
      ::Chouette::LineNotice.where(id: current_collection.select(:id)).or(
        ::Chouette::LineNotice.with_vehicle_journeys(global_scope.vehicle_journeys)
      ).distinct
    end

    collection :booking_arrangements do
      ::BookingArrangement.where(id: current_collection.select(:id)).or(
        ::BookingArrangement.where(
          id: ::BookingArrangement.joins(:journey_patterns)
                                  .where(journey_patterns: { id: global_scope.journey_patterns.select(:id).distinct })
                                  .select(:id)
        )
      ).distinct
    end

    collection :vehicle_journey_at_stops do
      current_collection.where(vehicle_journey: global_scope.vehicle_journeys)
    end

    collection :routes do
      current_collection.where(id: global_scope.vehicle_journeys.select(:route_id).distinct)
    end

    collection :journey_patterns do
      current_collection.where(id: global_scope.vehicle_journeys.select(:journey_pattern_id).distinct)
    end

    collection :shapes do
      current_collection.where(id: global_scope.journey_patterns.select(:shape_id).distinct)
    end

    collection :stop_points do
      current_collection.distinct.where(route: global_scope.routes)
    end

    collection :routing_constraint_zones do
      current_collection.where(route: global_scope.routes)
    end

    collection :stop_areas do
      current_collection.where(
        Chouette::StopArea.arel_table[:id].in(
          Arel::Nodes::Union.new(
            global_scope.stop_points.select(:stop_area_id).distinct.arel.ast,
            global_scope.vehicle_journey_at_stops.where.not(stop_area_id: nil).select(:stop_area_id).distinct.arel.ast
          )
        )
      )
    end

    collection :time_tables do
      current_collection.where(
        id: global_scope.vehicle_journeys
                        .joins(:vehicle_journey_time_table_relationships)
                        .select(:time_table_id)
                        .distinct
      )
    end
  end
end
