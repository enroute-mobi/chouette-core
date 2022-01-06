class UpdateNotificationRules < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      change_table(:notification_rules) do |t|
        t.column(:user_ids, :bigint, array: true, default: [])
        t.column(:external_email, :string)
        t.column(:priority, :integer, default: 10)
        t.column(:target_type, :string)
        t.column(:line_ids, :bigint, array: true, default: [])
        t.column(:rule_type, :string)
        t.column(:operation_statuses, :string, array: true, default: [])
        t.index(:workbench_id)
      end

      NotificationRule.reset_column_information
      # Prevent loading models
      NotificationRule.update_all(
        priority: 10,
        target_type: 'workbench',
        rule_type: 'block'
      )
      NotificationRule.update_all('line_ids = ARRAY[line_id]')

      remove_column :notification_rules, :line_id
    end
  end
end
