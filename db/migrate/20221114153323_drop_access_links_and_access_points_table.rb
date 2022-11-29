class DropAccessLinksAndAccessPointsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :access_links
    drop_table :access_points
  end
end
