class DropNotificationsTable < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :notifications
    end
  end
end
