class RemoveColumnsFromExportsTable < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      remove_columns :exports, :parent_id, :parent_type, :notified_parent_at
    end
  end
end
