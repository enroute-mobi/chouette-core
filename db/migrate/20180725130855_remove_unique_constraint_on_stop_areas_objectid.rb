class RemoveUniqueConstraintOnStopAreasObjectid < ActiveRecord::Migration
  def change
    remove_index :stop_areas, name: "stop_areas_objectid_key"
    add_index :stop_areas, ["objectid"], name: "stop_areas_objectid_key"
  end
end
