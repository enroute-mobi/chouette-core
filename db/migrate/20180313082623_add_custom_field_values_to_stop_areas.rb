class AddCustomFieldValuesToStopAreas < ActiveRecord::Migration
  def change
    add_column :stop_areas, :custom_field_values, :jsonb
  end
end
