class DropPurchaseWindowsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :purchase_windows, :purchase_windows_vehicle_journeys
  end
end
