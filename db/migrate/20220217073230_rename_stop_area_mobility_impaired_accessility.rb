class RenameStopAreaMobilityImpairedAccessility < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      rename_column :stop_areas, :mobility_impaired_accessility, :mobility_impaired_accessibility
    end
  end
end
