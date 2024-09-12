class CreateStopAreaGroupsAndLineGroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :stop_area_groups do |t|
        t.string :name
        t.text :description
        t.references :stop_area_referential
        t.references :stop_area_provider

        t.timestamps
      end
      create_table :line_groups do |t|
        t.string :name
        t.text :description
        t.references :line_referential
        t.references :line_provider

        t.timestamps
      end
      create_table :stop_area_group_members do |t|
        t.references :group, index: false, foreign_key: { to_table: :stop_area_groups }, null: false
        t.references :stop_area, foreign_key: true, null: false

        t.timestamps
        t.index [:group_id, :stop_area_id], unique: true
      end
      create_table :line_group_members do |t|
        t.references :group, index: false, foreign_key: { to_table: :line_groups }, null: false
        t.references :line, foreign_key: true, null: false

        t.timestamps
        t.index [:group_id, :line_id], unique: true
      end
    end
  end
end
