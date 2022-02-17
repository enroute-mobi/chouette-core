class AddObjectIdToLineRoutingConstraintZone < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :line_routing_constraint_zones, :objectid, :string, null: false
    end
  end
end