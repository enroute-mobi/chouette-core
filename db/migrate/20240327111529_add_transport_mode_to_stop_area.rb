class AddTransportModeToStopArea < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :stop_areas, :transport_mode, :string
    end
  end
end
