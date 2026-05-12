# frozen_string_literal: true

class AddAllowedStopAreaTypesToStopAreaProviders < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_area_providers, :allowed_stop_area_types, :string, array: true
    end
  end
end
