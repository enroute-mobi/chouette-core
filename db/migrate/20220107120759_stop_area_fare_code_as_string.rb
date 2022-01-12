class StopAreaFareCodeAsString < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      change_column :stop_areas, :fare_code, :string
    end
  end
end
