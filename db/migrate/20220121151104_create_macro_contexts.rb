class CreateMacroContexts < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      create_table :macro_contexts do |t|
        t.references :macro_list

        t.string :name
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end
      create_table :macro_context_runs do |t|
        t.references :macro_context
        t.references :macro_list_run

        t.string :name
        t.jsonb :options, default: {}
        t.text :comments

        t.timestamps
      end
    end
  end
end