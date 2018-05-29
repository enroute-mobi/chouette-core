class SpringCleanup < ActiveRecord::Migration
  def change
    drop_table :timebands, :journey_frequencies, :vehicle_journey_frequencies, :access_points, :access_links
  end
end
