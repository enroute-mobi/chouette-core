class RemoveDurationsFromConnectionLinks < ActiveRecord::Migration[4.2]
  def change
    remove_column :connection_links, :default_duration
    remove_column :connection_links, :frequent_traveller_duration
    remove_column :connection_links, :occasional_traveller_duration
    remove_column :connection_links, :mobility_restricted_traveller_duration
  end
end
