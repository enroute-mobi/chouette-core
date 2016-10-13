class AddStartedAtToStopAreaReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :stop_area_referential_syncs, :started_at, :datetime
  end
end
