class AddStopAreaReferentialToConnectionLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :connection_links, :stop_area_referential_id, :integer
    add_index :connection_links, :stop_area_referential_id
  end
end
