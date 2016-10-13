class AddEndedAtToStopAreaReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :stop_area_referential_syncs, :ended_at, :datetime
  end
end
