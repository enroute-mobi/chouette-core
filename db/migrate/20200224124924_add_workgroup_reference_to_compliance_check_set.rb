class AddWorkgroupReferenceToComplianceCheckSet < ActiveRecord::Migration[5.2]
  def up
    add_reference :compliance_check_sets, :workgroup, index: true, foreign_key: true
    ComplianceCheckSet.where(workbench: nil).destroy_all
    ComplianceCheckSet.where.not(workbench: nil).each do |ccs|
      ccs.update  workgroup: ccs.workbench.workgroup
    end
  end

  def down
    remove_reference :compliance_check_sets, :workgroup, index: true, foreign_key: true
    # raise IrreversibleMigration
  end
end
