class AddWaypoints < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table "waypoints" do |t|
        t.string "name"
        t.integer "position", null: false
        t.string "waypoint_type", null: false
        t.references "shape"
        t.float "coordinates", array: true
        t.timestamps
      end
    end
  end
end
