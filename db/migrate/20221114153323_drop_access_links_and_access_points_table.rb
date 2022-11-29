class DropAccessLinksAndAccessPointsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :access_links, if_exists: true
    drop_table :access_points, if_exists: true
  end
end
