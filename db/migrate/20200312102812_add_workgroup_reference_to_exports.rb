class AddWorkgroupReferenceToExports < ActiveRecord::Migration[5.2]

  def up
    on_public_schema_only do
      add_reference :exports, :workgroup, index: true, foreign_key: true
      Export::Base.where.not(workbench: nil).each do |export|
        export.update  workgroup_id: export.workbench.workgroup_id
      end
    end
  end

  def down
    on_public_schema_only do
      remove_reference :exports, :workgroup, index: true, foreign_key: true
    end
  end
end
