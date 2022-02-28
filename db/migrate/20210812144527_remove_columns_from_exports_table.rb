class RemoveColumnsFromExportsTable < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      remove_columns :exports, :parent_id, :parent_type
    end
  end

  def down
    on_public_schema_only do
      add_column :exports, :parent_id, :bigint
      add_column :exports, :parent_type, :string
    end
  end
end
