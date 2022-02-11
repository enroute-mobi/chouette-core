class AddNewAccessibilityAttributesToStopArea < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_areas, :mobility_impaired_accessility, :string
      add_column :stop_areas, :wheelchair_accessibility, :string
      add_column :stop_areas, :step_free_accessibility, :string
      add_column :stop_areas, :escalator_free_accessibility, :string
      add_column :stop_areas, :lift_free_accessibility, :string
      add_column :stop_areas, :audible_signals_availability, :string
      add_column :stop_areas, :visual_signs_availability, :string
      add_column :stop_areas, :accessibility_limitation_description, :text
    end
  end
end