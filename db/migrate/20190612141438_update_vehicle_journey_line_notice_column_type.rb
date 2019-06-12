class UpdateVehicleJourneyLineNoticeColumnType < ActiveRecord::Migration[5.2]
  def up
    change_column :vehicle_journeys, :line_notice_ids, :bigint, array: true
  end

  def down
    change_column :vehicle_journeys, :line_notice_ids, :integer, array: true
  end
end
