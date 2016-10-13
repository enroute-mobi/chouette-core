class RenameOfferWorkbenchToWorkbench < ActiveRecord::Migration
  def self.up
    rename_table :offer_workbenches, :workbenches
    rename_column :referentials, :offer_workbench_id, :workbench_id
  end

  def self.down
    rename_table :workbenches, :offer_workbenches
    rename_column :referentials, :workbench_id, :offer_workbench_id
  end
end
