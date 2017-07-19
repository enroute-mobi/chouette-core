class AddParentTypeAndParentIdToImports < ActiveRecord::Migration
  def change
    add_column :imports, :parent_id, :bigint
    add_column :imports, :parent_type, :string
  end
end
