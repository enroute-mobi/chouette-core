# frozen_string_literal: true

class RenameStopAreaProvidersDisableStopAreaManualCreation < ActiveRecord::Migration[7.2]
  def change
    on_public_schema_only do
      rename_column :stop_area_providers, :disable_stop_area_manual_creation, :disable_stop_area_manual_edit
    end
  end
end
