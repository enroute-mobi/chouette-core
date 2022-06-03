class AddUniquenessToShortNameForCodeSpace < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_index :code_spaces, [:short_name, :workgroup_id], unique: true
    end
  end
end
