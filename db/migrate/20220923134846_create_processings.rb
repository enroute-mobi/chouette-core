class CreateProcessings < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      rename_column :processing_rules, :processing_id, :processable_id
      rename_column :processing_rules, :processing_type, :processable_type

      create_table :processings do |t|
        t.string :step
        t.references :workbench
        t.references :workgroup
        t.references :operation, polymorphic: true
        t.references :processed, polymorphic: true
        t.references :processing_rule
      end
    end
  end
end
