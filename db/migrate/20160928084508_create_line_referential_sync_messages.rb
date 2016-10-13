class CreateLineReferentialSyncMessages < ActiveRecord::Migration
  def self.up
    execute 'CREATE EXTENSION IF NOT EXISTS hstore SCHEMA shared_extensions;'

    create_table :line_referential_sync_messages do |t|
      t.integer :criticity
      t.string :message_key
      t.hstore :message_attributs
      t.references :line_referential_sync
      t.timestamps
    end

    add_index :line_referential_sync_messages, :line_referential_sync_id, name: 'line_referential_sync_id'
  end

  def self.down
    execute 'DROP EXTENSION IF EXISTS hstore SCHEMA shared_extensions;'
    drop_table :line_referential_sync_messages
  end
end
