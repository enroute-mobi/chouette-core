class AddStopAreaToWaypoints < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_reference :waypoints, :stop_area
    end
  end
end