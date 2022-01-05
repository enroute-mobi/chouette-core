class CreateMacroRuns < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :macro_list_runs do |t|
        t.references :workbench
        t.references :referential

        # Operation
        t.string :status
        t.string :error_uuid
        t.string :creator
        t.datetime :started_at
        t.datetime :ended_at

        t.timestamps
      end
      create_table :macro_runs do |t|
        t.string :type, null: false
        t.references :macro_list_run
        t.integer :position, null: false

        t.text :name
        t.text :comments
        t.jsonb :options, default: {}
        t.timestamps

        t.index [:macro_list_run_id, :position], unique: true
      end
    end
  end
end
