class DropUselessTables < ActiveRecord::Migration[5.2]
  def change
  	drop_table :facilities
  	drop_table :pt_links
  	drop_table :routing_constraints_lines
  	drop_table :stop_areas_stop_areas
  end
end
