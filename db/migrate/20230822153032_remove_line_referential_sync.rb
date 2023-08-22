class RemoveLineReferentialSync < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :line_referential_sync_messages
      drop_table :line_referential_syncs

      remove_column :line_referentials, :sync_interval
    end
  end
end
