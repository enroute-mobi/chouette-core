# frozen_string_literal: true

class AddDisableStopAreaManualCreationToStopAreaProviders < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      change_table :stop_area_providers do |t|
        t.boolean :disable_stop_area_manual_creation, null: false, default: false
      end
    end
  end
end
