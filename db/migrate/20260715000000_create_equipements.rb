# frozen_string_literal: true

class CreateEquipements < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table 'equipements' do |t|
        t.string 'name'
        t.string 'public_code'
        t.references 'stop_area'
        t.references 'shape_provider'
        t.references 'shape_referential'
        t.boolean 'fixed', default: false
        t.boolean 'out_of_order', default: false
        t.string 'mobility_impaired_accessibility'
        t.string 'wheelchair_accessibility'
        t.string 'step_free_accessibility'
        t.string 'escalator_free_accessibility'
        t.string 'lift_free_accessibility'
        t.string 'audible_signals_availability'
        t.string 'visual_signs_availability'
        t.text 'description'
        t.timestamps
      end
    end
  end
end
