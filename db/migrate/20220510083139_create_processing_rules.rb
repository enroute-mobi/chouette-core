class CreateProcessingRules < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :processing_rules do |t|
        t.references :workbench
        t.string :name
        t.references :processable, polymorphic: true, index: true
        t.string :operation_step
        t.timestamps
      end
    end
  end
end
