class AddPositionToWidgets < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      add_column :widgets, :x, :integer, default: 0, null: false
      add_column :widgets, :y, :integer, default: 0, null: false
      add_column :widgets, :width, :integer, default: 1, null: false
      add_column :widgets, :height, :integer, default: 2, null: false
    end
  end
end
