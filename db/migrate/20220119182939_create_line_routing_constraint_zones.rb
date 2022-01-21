class CreateLineRoutingConstraintZones < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :line_routing_constraint_zones do |t|
        t.string :name
        t.bigint :line_ids, array: true
        t.bigint :stop_area_ids, array: true
        t.bigint :line_referential_id
        t.bigint :line_provider_id
        t.timestamps
      end
    end
  end
end
