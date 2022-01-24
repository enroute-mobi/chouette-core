class RenameRunToMacroRun < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      rename_column :macro_messages, :run_id, :macro_run_id
    end
  end
end
