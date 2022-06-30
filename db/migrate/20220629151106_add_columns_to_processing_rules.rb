class AddColumnsToProcessingRules < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
       change_table :processing_rules do |t|
        t.references :workgroup
        t.bigint :target_workbench_ids, array: true, default: []
      end
    end
  end
end
