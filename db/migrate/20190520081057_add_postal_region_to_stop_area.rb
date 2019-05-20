class AddPostalRegionToStopArea < ActiveRecord::Migration[5.2]
  def change
    add_column :stop_areas, :postal_region, :string
  end
end
