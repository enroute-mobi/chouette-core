class AddWorkgroupReferenceToExports < ActiveRecord::Migration[5.2]
  def up
    add_reference :exports, :workgroup, index: true, foreign_key: true
    Export::Base.where(workbench: nil).destroy_all
    Export::Base.where.not(workbench: nil).each do |export|
      export.update  workgroup: export.workbench.workgroup
    end
  end

  def down
    remove_reference :exports, :workgroup, index: true, foreign_key: true
    # raise IrreversibleMigration
  end
end
