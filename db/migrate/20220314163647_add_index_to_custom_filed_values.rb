class AddIndexToCustomFiledValues < ActiveRecord::Migration[5.2]
  def change
    enable_extension "btree_gin"

    on_public_schema_only do
      add_index :companies, :custom_field_values, using: :gin
      add_index :stop_areas, :custom_field_values, using: :gin
    end

    add_index :journey_patterns, :custom_field_values, using: :gin
    add_index :vehicle_journeys, :custom_field_values, using: :gin
  end
end
