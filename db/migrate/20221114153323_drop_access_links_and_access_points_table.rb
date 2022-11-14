class DropAccessLinksAndAccessPointsTable < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      drop_table :access_links
      drop_table :access_points
    end
  end
end
