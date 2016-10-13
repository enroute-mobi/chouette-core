class AddStatusToStopAreaReferentialSyncs < ActiveRecord::Migration
  def change
    add_column :stop_area_referential_syncs, :status, :string
  end
end
