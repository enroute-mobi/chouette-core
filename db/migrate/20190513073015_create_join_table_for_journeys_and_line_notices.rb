class CreateJoinTableForJourneysAndLineNotices < ActiveRecord::Migration[5.2]
  def change
    create_table :line_notices_vehicle_journeys, id: false do |t|
      t.integer :vehicle_journey_id, limit: 8
      t.integer :line_notice_id, limit: 8
    end
    add_index :line_notices_vehicle_journeys, [:vehicle_journey_id, :line_notice_id], name: :line_notices_vehicle_journeys_index
  end
end
