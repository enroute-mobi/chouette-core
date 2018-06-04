class AddNewIdToMerges < ActiveRecord::Migration
  def change
    add_column :merges, :new_id, :integer, limit: 8
    add_index :merges, :new_id
  end
end
