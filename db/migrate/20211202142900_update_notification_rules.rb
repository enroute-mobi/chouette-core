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

        reversible do |dir|
          NotificationRule.find_each do |nf|

            dir.up do
              # line_ids
              nf.assign_attributes(line_ids: [nf.line_id])

              # target_type
              nf.assign_attributes(target_type: 'workbench')

              # rule_type
              nf.assign_attributes(rule_type: 'block')

              t.remove(:line_id)
            end
          
            dir.down do
              # line_ids
              nf.assign_attributes(line_id: nf.lines_ids.first)

              t.column(:line_id)
            end

            nf.save
          end
        end

      end
    end
  end
end
