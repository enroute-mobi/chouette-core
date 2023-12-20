class AddNewAccessibilityAttributesToLine < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :lines, :mobility_impaired_accessility, :string
      add_column :lines, :wheelchair_accessibility, :string
      add_column :lines, :step_free_accessibility, :string
      add_column :lines, :escalator_free_accessibility, :string
      add_column :lines, :lift_free_accessibility, :string
      add_column :lines, :audible_signals_availability, :string
      add_column :lines, :visual_signs_availability, :string
      add_column :lines, :accessibility_limitation_description, :text
    end
  end
end
