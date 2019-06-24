class CreateNotificationRules < ActiveRecord::Migration[4.2]
  def change
    on_public_schema_only do
      create_table :notification_rules do |t|
        t.string :notification_type
        t.daterange :period
        t.integer :line_id, limit: 8
        t.integer :workbench_id, limit: 8

        t.timestamps
      end
    end
  end
end
