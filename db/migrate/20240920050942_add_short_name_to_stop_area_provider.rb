# frozen_string_literal: true

class AddShortNameToStopAreaProvider < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_area_providers, :short_name, :string
    end
  end
end
