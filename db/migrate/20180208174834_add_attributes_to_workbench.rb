class AddAttributesToWorkbench < ActiveRecord::Migration
  def change
    add_column :workbenches, :import_compliance_control_set_id, :integer, limit: 8
    add_column :workbenches, :merge_compliance_control_set_id, :integer, limit: 8

    add_index :workbenches, :import_compliance_control_set_id
    add_index :workbenches, :merge_compliance_control_set_id
  end
end
