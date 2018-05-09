class AddImportComplianceControlSetsToWorkgroups < ActiveRecord::Migration
  def change
    add_column :workgroups, :import_compliance_control_set_ids, :integer, array: true, default: []
  end
end
