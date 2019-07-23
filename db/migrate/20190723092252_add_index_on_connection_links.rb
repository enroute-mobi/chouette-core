class AddIndexOnConnectionLinks < ActiveRecord::Migration[5.2]
  def change
    on_public_schema_only do
      add_index :connection_links, [:stop_area_referential_id, :departure_id, :arrival_id, :both_ways], name: :connection_links_compound
    end
  end
end
