class CreateStopAreaProviders < ActiveRecord::Migration
  def change
    create_table :stop_area_providers do |t|
      t.string :objectid
      t.string :name
      t.integer :stop_area_referential_id, limit: 8

      t.timestamps null: false
    end

    add_column :organisations, :stop_area_provider_id, :integer, limit: 8

    create_table :stop_areas_stop_area_providers, index: false do |t|
      t.integer :stop_area_provider_id, limit: 8
      t.integer :stop_area_id, limit: 8
    end

    add_index :stop_areas_stop_area_providers, [:stop_area_provider_id, :stop_area_id], name: :stop_areas_stop_area_providers_compound

  end
end
