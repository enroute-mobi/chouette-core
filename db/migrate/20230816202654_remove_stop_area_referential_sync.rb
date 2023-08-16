class RemoveStopAreaReferentialSync < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :stop_area_referential_sync_messages
      drop_table :stop_area_referential_syncs
    end
  end
end
