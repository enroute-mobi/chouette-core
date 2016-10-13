class DropLineSyncOperations < ActiveRecord::Migration
  def up
    drop_table :line_sync_operations if table_exists?(:line_sync_operations)
  end

  def down
    create_table :line_sync_operations do |t|
      t.string :status
      t.references :line_referential_sync, index: true

      t.timestamps
    end
  end
end
