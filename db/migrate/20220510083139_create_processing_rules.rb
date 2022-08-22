class CreateProcessingRules < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :processing_rules do |t|
        t.references :workgroup
        t.references :workbench
        t.string :type
        t.string :name
        t.references :processable, polymorphic: true
        t.string :operation_step
        t.bigint :target_workbench_ids, array: true, default: []
        t.timestamps
      end
    end
  end
end
