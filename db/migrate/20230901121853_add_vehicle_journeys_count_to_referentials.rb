class AddVehicleJourneysCountToReferentials < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :referentials, :vehicle_journeys_count, :integer
    end
  end
end
