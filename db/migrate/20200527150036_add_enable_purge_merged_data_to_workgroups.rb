class AddEnablePurgeMergedDataToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_column :workgroups, :enable_purge_merged_data, :boolean, default: false
    end
  end
end
