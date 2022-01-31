class AddTypeToMacroContexts < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :macro_contexts, :type, :string, null: false
      add_column :macro_context_runs, :type, :string, null: false
    end
  end
end
