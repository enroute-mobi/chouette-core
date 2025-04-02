class AddReferentialFlexibleAttributes < ActiveRecord::Migration[5.2]
  def change
    change_table :stop_points do |t|
      t.boolean :flexible, default: false, null: false
    end

    change_table :vehicle_journey_at_stops do |t|
      t.integer :earliest_departure_time_of_day
      t.integer :latest_arrival_time_of_day
    end
  end
end
