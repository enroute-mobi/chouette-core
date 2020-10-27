class DropStopAreasStopAreaProvidersTable < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :stop_area_providers_areas do |t|
        t.bigint "stop_area_provider_id"
        t.bigint "stop_area_id"
        t.index ["stop_area_provider_id", "stop_area_id"], name: "stop_areas_stop_area_providers_compound"
      end
    end
  end
end
