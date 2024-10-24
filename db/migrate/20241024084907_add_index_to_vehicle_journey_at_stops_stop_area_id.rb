class AddIndexToVehicleJourneyAtStopsStopAreaId < ActiveRecord::Migration[5.2]
  def change
    remove_index :vehicle_journey_at_stops, column: :vehicle_journey_id, name: 'index_vehicle_journey_at_stops_on_vehicle_journey_id'
    add_index :vehicle_journey_at_stops, [:vehicle_journey_id, :stop_area_id], name: 'index_vjas_on_vehicle_journey_id_and_stop_area_id'
  end
end
