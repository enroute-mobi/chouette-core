class AddReferentToStopAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :stop_areas, :referent_id, :integer
  end
end
