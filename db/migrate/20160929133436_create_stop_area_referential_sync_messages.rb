class CreateStopAreaReferentialSyncMessages < ActiveRecord::Migration
  def change
    create_table :stop_area_referential_sync_messages do |t|
      t.integer :criticity
      t.string :message_key
      t.hstore :message_attributs
      t.references :stop_area_referential_sync

      t.timestamps
    end
    add_index :stop_area_referential_sync_messages, :stop_area_referential_sync_id, name: 'stop_area_referential_sync_id'
  end
end
