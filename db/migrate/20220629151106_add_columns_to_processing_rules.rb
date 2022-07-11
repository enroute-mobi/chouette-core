class AddColumnsToProcessingRules < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
       change_table :processing_rules do |t|
        t.boolean :workgroup_rule, default: false
        t.bigint :target_workbench_ids, array: true, default: []
      end
    end
  end
end
