class AddBothwaysOnConnectionLinks < ActiveRecord::Migration
  def change
    on_public_schema_only do
      add_column :connection_links, :both_ways, :boolean, default: false
    end
  end
end
