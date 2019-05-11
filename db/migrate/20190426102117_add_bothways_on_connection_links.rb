class AddBothwaysOnConnectionLinks < ActiveRecord::Migration[4.2]
  def change
    on_public_schema_only do
      add_column :connection_links, :both_ways, :boolean, default: false
    end
  end
end
