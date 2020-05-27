class AddEnablePurgeMergedDataToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    add_column :workgroups, :enable_purge_merged_data, :boolean
  end
end
