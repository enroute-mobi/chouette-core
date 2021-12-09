class UpdateNotificationRules < ActiveRecord::Migration[5.2]

  def change
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
  
        reversible do |dir|
          NotificationRule.find_each do |nf|
            dir.up do
              nf.assign_attributes(
                priority: 10,
                target_type: 'workbench',
                rule_type: 'block',
                line_ids: [nf.line_id]
              )
            end
          
            dir.down do
              nf.assign_attributes(line_id: nf.line_ids.first)
            end

            nf.save
          end
        end

        revert { t.column(:line_id, :bigint) }
      end
    end
  end
end
