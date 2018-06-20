class RemoveReferentialId < ActiveRecord::Migration
  def up
    remove_column :purchase_windows, :referential_id
  end
end
