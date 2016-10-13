class DropStopAreaSyncOperations < ActiveRecord::Migration
  def up
    drop_table :stop_area_sync_operations if table_exists?(:stop_area_sync_operations)
  end

  def down
    create_table :stop_area_sync_operations do |t|
      t.string :status
      t.references :stop_area_referential_sync
      t.string :message
      t.timestamps
    end
    add_index :stop_area_sync_operations, :stop_area_referential_sync_id, name: 'stop_area_referential_sync_id'
  end
end
