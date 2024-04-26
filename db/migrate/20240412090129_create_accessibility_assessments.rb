class CreateAccessibilityAssessments < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :accessibility_assessments do |t|
        t.uuid :uuid, default: -> { "gen_random_uuid()" }, null: false
        t.string :name
        t.string :mobility_impaired_accessibility
        t.string :wheelchair_accessibility
        t.string :step_free_accessibility
        t.string :escalator_free_accessibility
        t.string :lift_free_accessibility
        t.string :audible_signals_availability
        t.string :visual_signs_availability
        t.text :accessibility_limitation_description
        t.references :shape_referential
        t.references :shape_provider

        t.timestamps
      end

      add_reference :vehicle_journeys, :accessibility_assessment
    end
  end
end
