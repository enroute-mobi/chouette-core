class AddStopAreaRefToVehicleJourneyAtStops < ActiveRecord::Migration[5.2]
  def change
    add_reference :vehicle_journey_at_stops, :stop_area, type: :bigint, index: true
  end
end
