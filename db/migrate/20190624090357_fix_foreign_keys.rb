class FixForeignKeys < ActiveRecord::Migration[5.2]
  def change
    change_column :vehicle_journeys, :ignored_routing_contraint_zone_ids, :bigint, array: true
    change_column :vehicle_journeys, :ignored_stop_area_routing_constraint_ids, :bigint, array: true
  end
end
