class ChangeIndexForRawImport < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_index :raw_imports, column: [:model_type, :model_id]
      add_index(:raw_imports, [:model_id, :model_type], unique: true)
    end
  end
end
