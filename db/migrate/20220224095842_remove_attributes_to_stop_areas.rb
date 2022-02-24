class RemoveAttributesToStopAreas < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_column :stop_areas, :stairs_availability
      remove_column :stop_areas, :lift_availability
      remove_column :stop_areas, :int_user_needs
    end
  end
end
