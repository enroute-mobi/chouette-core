class AddDeletedAtToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    add_column :workgroups, :deleted_at, :datetime
  end
end
