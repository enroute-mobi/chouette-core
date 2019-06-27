class SetDefaultForLineNoticeIds < ActiveRecord::Migration[5.2]
  def change
    change_column :vehicle_journeys, :line_notice_ids, :bigint, array: true, default: []
    Referential.active.each do |r|
      r.switch do
        Chouette::VehicleJourney.where(line_notice_ids: nil).update_all line_notice_ids: []
      end
    end
  end
end
