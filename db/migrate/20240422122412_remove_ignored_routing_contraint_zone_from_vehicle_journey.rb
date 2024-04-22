class RemoveIgnoredRoutingContraintZoneFromVehicleJourney < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :vehicle_journeys, :ignored_routing_contraint_zone_ids
      remove_column :vehicle_journeys, :ignored_stop_area_routing_constraint_ids
    end
  end
end
