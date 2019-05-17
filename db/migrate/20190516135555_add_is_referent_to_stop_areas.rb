class AddIsReferentToStopAreas < ActiveRecord::Migration[5.2]
  def change
    add_column :stop_areas, :is_referent, :bool, default: false
  end
end
