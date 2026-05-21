# frozen_string_literal: true

class AddOccupancyToVehicleJourneysAndAtStops < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicle_journeys, :occupancy_level, :string
    add_column :vehicle_journeys, :occupancy_percentage, :integer

    add_column :vehicle_journey_at_stops, :occupancy_level, :string
    add_column :vehicle_journey_at_stops, :occupancy_percentage, :integer
  end
end
