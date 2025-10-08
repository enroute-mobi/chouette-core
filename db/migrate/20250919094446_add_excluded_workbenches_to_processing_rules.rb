class AddExcludedWorkbenchesToProcessingRules < ActiveRecord::Migration[7.0]
  def change
    on_public_schema_only do
      add_column :processing_rules, :excluded_workbench_ids, :bigint, array: true, default: []
    end
  end
end
