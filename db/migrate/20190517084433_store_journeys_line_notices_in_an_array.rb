class StoreJourneysLineNoticesInAnArray < ActiveRecord::Migration[5.2]
  def change
    drop_table :line_notices_vehicle_journeys
    add_column :vehicle_journeys, :line_notice_ids, :integer, array: true
  end
end
