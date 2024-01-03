# frozen_string_literal: true

class DropComplianceControlTables < ActiveRecord::Migration[5.2]
  # rubocop:disable Metrics/MethodLength
  def up
    on_public_schema_only do
      drop_table :compliance_controls
      drop_table :compliance_control_blocks
      drop_table :compliance_control_sets

      drop_table :compliance_check_messages
      drop_table :compliance_check_resources
      drop_table :compliance_checks
      drop_table :compliance_check_blocks
      drop_table :compliance_check_sets

      remove_column :workgroups, :compliance_control_set_ids
      remove_column :workbenches, :owner_compliance_control_set_ids
    end
  end
  # rubocop:enable Metrics/MethodLength

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
