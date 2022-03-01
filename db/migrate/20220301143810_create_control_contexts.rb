class CreateControlContexts < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :control_contexts do |t|
        t.references :control_list

        t.string :name
        t.string :type, null: false
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end
      create_table :control_context_runs do |t|
        t.references :control_list_run

        t.string :name
        t.string :type, null: false
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end
    end
  end
end
