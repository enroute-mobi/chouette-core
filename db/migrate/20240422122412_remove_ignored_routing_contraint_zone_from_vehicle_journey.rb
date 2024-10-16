# frozen_string_literal: true

class RemoveIgnoredRoutingContraintZoneFromVehicleJourney < ActiveRecord::Migration[5.2]
  def change
    remove_column :vehicle_journeys, :ignored_routing_contraint_zone_ids
    remove_column :vehicle_journeys, :ignored_stop_area_routing_constraint_ids
  end
end
